from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow_clickhouse_plugin.operators.clickhouse_operator import ClickHouseOperator
from airflow.utils.task_group import TaskGroup
from airflow.operators.empty import EmptyOperator
from datetime import datetime, timedelta

START_DATE = "2021-01-01"
END_DATE = "2021-03-01"
DB_SCHEMA = "retail_dwh"
GP_CONN = "gp_retail_dwh"
CH_CONN = "ch_retail_dwh"

default_args = {
    'owner': 'retail_dwh',
    'depends_on_past': False,
    'email_on_failure': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=3),
}


def generate_months(start_str, end_str):
    start = datetime.strptime(start_str, '%Y-%m-%d')
    end = datetime.strptime(end_str, '%Y-%m-%d')
    months = []
    current = start
    while current < end:
        months.append(current.strftime('%Y-%m-%d'))
        if current.month == 12:
            current = current.replace(year=current.year + 1, month=1)
        else:
            current = current.replace(month=current.month + 1)
    return months


MONTHS = generate_months(START_DATE, END_DATE)


with DAG(
    dag_id='retail_dwh_retail_etl',
    default_args=default_args,
    start_date=datetime(2021, 1, 1),
    schedule=None,
    catchup=False,
    tags=['retail_dwh', 'retail'],
    description='ETL: Greenplum >> ClickHouse',
) as dag:
    with TaskGroup('load_dicts') as load_dicts:
        PostgresOperator(
            task_id='load_stores',
            postgres_conn_id=GP_CONN,
            sql=f"SELECT {DB_SCHEMA}.f_full_load('stores', 'store_ext');",
        )

        PostgresOperator(
            task_id='load_promos',
            postgres_conn_id=GP_CONN,
            sql=f"SELECT {DB_SCHEMA}.f_full_load('promos', 'promos_ext');",
        )

        PostgresOperator(
            task_id='load_promo_types',
            postgres_conn_id=GP_CONN,
            sql=f"SELECT {DB_SCHEMA}.f_full_load('promo_types', 'promo_types_ext');",
        )


    previous_month_dummy = None

    with TaskGroup('load_facts') as load_facts:
        for month in MONTHS:
            bh = PostgresOperator(
                task_id=f'bills_head_{month.replace("-", "_")}',
                postgres_conn_id=GP_CONN,
                sql=f"SELECT {DB_SCHEMA}.f_delta_partition('bills_head', 'bills_head_ext', '{month}'::date);",
            )

            bi = PostgresOperator(
                task_id=f'bills_item_{month.replace("-", "_")}',
                postgres_conn_id=GP_CONN,
                sql=f"SELECT {DB_SCHEMA}.f_delta_partition('bills_item', 'bills_item_ext', '{month}'::date);",
            )

            cp = PostgresOperator(
                task_id=f'coupons_{month.replace("-", "_")}',
                postgres_conn_id=GP_CONN,
                sql=f"SELECT {DB_SCHEMA}.f_delta_partition('coupons', 'coupons_ext', '{month}'::date);",
            )

            tr = PostgresOperator(
                task_id=f'traffic_{month.replace("-", "_")}',
                postgres_conn_id=GP_CONN,
                sql=f"SELECT {DB_SCHEMA}.f_delta_partition('traffic', 'traffic_ext_view', '{month}'::date);",
            )

            month_dummy = EmptyOperator(
                task_id=f'month_{month.replace("-", "_")}_complete'
            )

            [bh, bi, cp, tr] >> month_dummy

            if previous_month_dummy:
                previous_month_dummy >> [bh, bi, cp, tr]

            previous_month_dummy = month_dummy

    build_retail_daily = PostgresOperator(
        task_id='build_retail_daily',
        postgres_conn_id=GP_CONN,
        sql=f"SELECT {DB_SCHEMA}.f_load_retail_daily('{START_DATE}'::date, '{END_DATE}'::date);",
    )

    with TaskGroup('drop_ch_partitions') as drop_ch_partitions:
        for month in MONTHS:
            partition_name = month[:7].replace('-', '')
            ClickHouseOperator(
                task_id=f'drop_partition_{partition_name}',
                clickhouse_conn_id=CH_CONN,
                sql=f"""
                    ALTER TABLE {DB_SCHEMA}.retail_daily_local 
                    ON CLUSTER default_cluster 
                    DROP PARTITION '{partition_name}';
                """,
            )

    insert_new_data = ClickHouseOperator(
        task_id='insert_new_data',
        clickhouse_conn_id=CH_CONN,
        sql=f"""
            INSERT INTO {DB_SCHEMA}.retail_daily_distr
            SELECT * FROM {DB_SCHEMA}.retail_daily_ext
            WHERE dt >= '{START_DATE}' AND dt < '{END_DATE}';
        """,
    )

    (
        [load_dicts, load_facts]
        >> build_retail_daily
        >> drop_ch_partitions
        >> insert_new_data
    )
