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
    b.dt,
    b.plant,
    s.shop_name as shop_name,
    COALESCE(tg.turnover, 0) AS turnover,
    COALESCE(cd.discount, 0) AS coupon_discount,
    COALESCE(tg.turnover, 0) - COALESCE(cd.discount, 0) AS net_turnover,
    COALESCE(sia.sold_qty, 0) AS sold_qty,
    COALESCE(bca.bills_cnt, 0) AS bills_cnt,
    COALESCE(ta.traffic, 0) AS traffic,
    COALESCE(pia.promo_qty, 0) AS promo_qty,
    ROUND(COALESCE(pia.promo_qty, 0) * 100.0 / NULLIF(sia.sold_qty, 0), 1) AS share_discount_pct,
    ROUND(COALESCE(sia.sold_qty, 0) / NULLIF(bca.bills_cnt, 0), 2) AS avg_product,
    ROUND(COALESCE(bca.bills_cnt, 0) * 100.0 / NULLIF(ta.traffic, 0), 2) AS cof_convertion_shop,
    ROUND(COALESCE(tg.turnover, 0) / NULLIF(bca.bills_cnt, 0), 1) AS avg_check,
    ROUND(COALESCE(tg.turnover, 0) / NULLIF(ta.traffic, 0), 1) AS rev_per_visitor
FROM base b
JOIN std16_12fp.stores s ON s.shop_id = b.plant
LEFT JOIN turnover_agg tg  ON b.plant = tg.plant AND b.dt = tg.dt
LEFT JOIN sold_item_agg sia ON b.plant = sia.plant AND b.dt = sia.dt
LEFT JOIN bills_cnt_agg bca ON b.plant = bca.plant AND b.dt = bca.dt
LEFT JOIN traffic_agg ta ON b.plant = ta.plant AND b.dt = ta.dt
LEFT JOIN coupon_discount cd ON b.plant = cd.plant AND b.dt = cd.dt
LEFT JOIN promo_item_agg pia ON b.plant = pia.plant AND b.dt = pia.dt
ORDER BY b.dt, b.plant
-- для проверки
SELECT 
   plant,
    shop_name,
    SUM(turnover)          AS total_turnover,
    SUM(coupon_discount)   AS total_discount,
    SUM(net_turnover)      AS total_net,
    SUM(sold_qty)          AS total_sold,
    SUM(bills_cnt)         AS total_bills,
    SUM(traffic)           AS total_traffic,
    SUM(promo_qty)         AS total_promo_qty,
    ROUND(SUM(promo_qty) * 100.0 / NULLIF(SUM(sold_qty), 0), 1) AS check_share_discount_pct,
    ROUND(SUM(sold_qty) * 1.0 / NULLIF(SUM(bills_cnt), 0), 2) AS check_avg_product,
    ROUND(SUM(bills_cnt) * 100.0 / NULLIF(SUM(traffic), 0), 2) AS check_cof_convertion_shop,
    ROUND(SUM(turnover) * 1.0 / NULLIF(SUM(bills_cnt), 0), 1) AS check_avg_check,
    ROUND(SUM(turnover) * 1.0 / NULLIF(SUM(traffic), 0), 1) AS check_rev_per_visitor
	FROM std16_12fp.retail_daily_distr
GROUP BY plant,shop_name
ORDER BY plant;