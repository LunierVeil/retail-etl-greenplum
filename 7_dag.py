from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.operators.bash import BashOperator
from airflow.utils.task_group import TaskGroup
from datetime import datetime, timedelta

default_args = {
    'owner': 'std16_12fp',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=3)
}

with DAG(
    dag_id='std16_12fp_retail_etl_to_ch',
    default_args=default_args,
    start_date=datetime(2021, 1, 1),
    schedule='@daily',
    catchup=False,
    tags=['std16_12fp'],
    description='ETL: Postgres -> View -> ClickHouse'
) as dag:

    with TaskGroup('load_dicts') as load_dicts:

        PostgresOperator(
            task_id='load_stores',
            postgres_conn_id='gp_std16_12fp',
            sql="SELECT std16_12fp.f_full_load('stores', 'store_ext');"
        )

        PostgresOperator(
            task_id='load_promos',
            postgres_conn_id='gp_std16_12fp',
            sql="SELECT std16_12fp.f_full_load('promos','promos_ext');"
        )

        PostgresOperator(
            task_id='load_promo_types',
            postgres_conn_id='gp_std16_12fp',
            sql="SELECT std16_12fp.f_full_load('promo_types','promo_types_ext');"
        )

    months = ['2021-01-01', '2021-02-01']

    with TaskGroup('load_facts') as load_facts:

        for m in months:

            bh = PostgresOperator(
                task_id=f'bills_head_{m.replace("-", "_")}',
                postgres_conn_id='gp_std16_12fp',
                sql=f"""SELECT std16_12fp.f_delta_partition_facts('bills_head','bills_head_ext','{m}');"""
            )

            bi = PostgresOperator(
                task_id=f'bills_item_{m.replace("-", "_")}',
                postgres_conn_id='gp_std16_12fp',
                sql=f"""SELECT std16_12fp.f_delta_partition_facts('bills_item','bills_item_ext','{m}');"""
            )

            cp = PostgresOperator(
                task_id=f'coupons_{m.replace("-", "_")}',
                postgres_conn_id='gp_std16_12fp',
                sql=f"""SELECT std16_12fp.f_delta_partition_facts('coupons','coupons_ext','{m}');"""
            )

            tr = PostgresOperator(
                task_id=f'traffic_{m.replace("-", "_")}',
                postgres_conn_id='gp_std16_12fp',
                sql=f"""SELECT std16_12fp.f_delta_partition_traffic('traffic','traffic_ext','{m}');"""
            )

            bh >> bi >> cp >> tr

    build_gp_view = PostgresOperator(
        task_id='build_gp_view',
        postgres_conn_id='gp_std16_12fp',
        sql="""
        CREATE OR REPLACE VIEW std16_12fp.v_retail_daily AS
        WITH base AS (
            SELECT DISTINCT s.shop_id AS plant, date(bh.calday) AS dt
            FROM std16_12fp.bills_head bh
            CROSS JOIN std16_12fp.stores s
            WHERE bh.calday >= '2021-01-01' AND bh.calday < '2021-03-01'
        ),
        turnover_agg AS (
            SELECT bh.plant, date(bh.calday) AS dt, SUM(bi.rpa_sat) AS turnover
            FROM std16_12fp.bills_item bi
            JOIN std16_12fp.bills_head bh ON bh.billnum = bi.billnum
            WHERE bh.calday >= '2021-01-01' AND bh.calday < '2021-03-01'
            GROUP BY bh.plant, date(bh.calday)
        ),
        sold_item_agg AS (
            SELECT bh.plant, date(bh.calday) AS dt, SUM(bi.qty) AS sold_qty
            FROM std16_12fp.bills_item bi
            JOIN std16_12fp.bills_head bh ON bh.billnum = bi.billnum
            WHERE bh.calday >= '2021-01-01' AND bh.calday < '2021-03-01'
            GROUP BY bh.plant, date(bh.calday)
        ),
        bills_cnt_agg AS (
            SELECT bh.plant, date(bh.calday) AS dt, COUNT(DISTINCT bh.billnum) AS bills_cnt
            FROM std16_12fp.bills_head bh
            WHERE bh.calday >= '2021-01-01' AND bh.calday < '2021-03-01'
            GROUP BY bh.plant, date(bh.calday)
        ),
        traffic_agg AS (
            SELECT plant, date(calday) AS dt, SUM(quantity) AS traffic
            FROM std16_12fp.traffic
            WHERE calday >= '2021-01-01' AND calday < '2021-03-01'
            GROUP BY plant, date(calday)
        ),
        agg_items AS (
            SELECT billnum, material, SUM(rpa_sat) AS sum_rpa, SUM(qty) AS sum_qty
            FROM std16_12fp.bills_item
            WHERE calday >= '2021-01-01' AND calday < '2021-03-01'
            GROUP BY billnum, material
        ),
        coupons_calc AS (
            SELECT bh.plant, date(bh.calday) AS dt,
                CASE 
                    WHEN p.type_promos = 1 THEN p.discount_amount
                    WHEN p.type_promos = 2 THEN ROUND((ai.sum_rpa / NULLIF(ai.sum_qty, 0)) * p.discount_amount / 100.0, 2)
                    ELSE 0 
                END AS disc_value
            FROM std16_12fp.coupons c
            JOIN std16_12fp.promos p ON c.promo_id = p.promos_id
            JOIN std16_12fp.bills_head bh ON c.receipt_id = bh.billnum
            JOIN agg_items ai ON bh.billnum = ai.billnum AND c.product_id = ai.material
            WHERE bh.calday >= '2021-01-01' AND bh.calday < '2021-03-01'
        ),
        coupon_discount AS (
            SELECT plant, dt, SUM(disc_value) AS discount
            FROM coupons_calc
            GROUP BY plant, dt
        ),
        promo_item_agg AS (
            SELECT bh.plant, date(bh.calday) AS dt, COUNT(c.coupon_number) AS promo_qty
            FROM std16_12fp.coupons c
            JOIN std16_12fp.bills_head bh ON c.receipt_id = bh.billnum
            WHERE bh.calday >= '2021-01-01' AND bh.calday < '2021-03-01'
            GROUP BY bh.plant, date(bh.calday)
        )
        SELECT
            b.dt, b.plant, s.shop_name as shop_name,
            COALESCE(tg.turnover, 0) AS turnover,
            COALESCE(cd.discount, 0) AS coupon_discount,
            COALESCE(tg.turnover, 0) - COALESCE(cd.discount, 0) AS net_turnover,
            COALESCE(sia.sold_qty, 0) AS sold_qty,
            COALESCE(bca.bills_cnt, 0) AS bills_cnt,
            COALESCE(ta.traffic, 0) AS traffic,
            COALESCE(pia.promo_qty, 0) AS promo_qty,
            ROUND(COALESCE(pia.promo_qty, 0) * 100.0 / NULLIF(sia.sold_qty, 0), 1) AS share_discount_pct,
            ROUND(COALESCE(sia.sold_qty, 0) / NULLIF(bca.bills_cnt, 0), 2) AS avg_product,
            ROUND(COALESCE(bca.bills_cnt, 0) * 100.0 / NULLIF(ta.traffic, 0), 2) AS cof_conversion_shop,
            ROUND(COALESCE(tg.turnover, 0) / NULLIF(bca.bills_cnt, 0), 1) AS avg_check,
            ROUND(COALESCE(tg.turnover, 0) / NULLIF(ta.traffic, 0), 1) AS rev_per_visitor
        FROM base b
        JOIN std16_12fp.stores s ON s.shop_id = b.plant
        LEFT JOIN turnover_agg tg ON b.plant = tg.plant AND b.dt = tg.dt
        LEFT JOIN sold_item_agg sia ON b.plant = sia.plant AND b.dt = sia.dt
        LEFT JOIN bills_cnt_agg bca ON b.plant = bca.plant AND b.dt = bca.dt
        LEFT JOIN traffic_agg ta ON b.plant = ta.plant AND b.dt = ta.dt
        LEFT JOIN coupon_discount cd ON b.plant = cd.plant AND b.dt = cd.dt
        LEFT JOIN promo_item_agg pia ON b.plant = pia.plant AND b.dt = pia.dt;
        """
    )
    export_to_ch = BashOperator(
    task_id='export_to_clickhouse',
    bash_command="""
    curl -s 'http://192.168.214.206:8123/?user=std16_12&password=dHG4gTEg0Z8eVnAT' \
      -d "ALTER TABLE std16_12fp.retail_daily_distr DELETE WHERE dt >= '2021-01-01'; INSERT INTO std16_12fp.retail_daily_distr SELECT * FROM std16_12fp.v_retail_daily_ext;"
    """
	)
    validate_ch = BashOperator(
    task_id='validate_ch',
    bash_command="""
    curl -s 'http://192.168.214.206:8123/?user=std16_12&password=dHG4gTEg0Z8eVnAT' \
      -d "SELECT count() FROM std16_12fp.retail_daily_distr HAVING count() >= 800;"
    """
	)

    [load_dicts, load_facts] >> build_gp_view >> export_to_ch >> validate_ch
