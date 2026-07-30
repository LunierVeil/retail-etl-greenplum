-- Сверка итогов
SELECT 
    plant,
    shop_name,
    SUM(turnover) AS total_turnover, 
    ROUND(SUM(coupon_discount), 2) AS total_coupon_discount,
    ROUND(SUM(net_turnover), 2) AS total_net_turnover, 
    SUM(sold_qty) AS total_sold_qty, 
    SUM(bills_cnt) AS total_bills_cnt, 
    SUM(traffic) AS total_traffic, 
    SUM(promo_qty) AS total_promo_qty, 
    ROUND(SUM(promo_qty) * 100.0 / NULLIF(SUM(sold_qty), 0), 1) AS share_discount_pct, 
    ROUND(SUM(sold_qty) * 1.0 / NULLIF(SUM(bills_cnt), 0), 2) AS avg_product,
    ROUND(SUM(bills_cnt) * 100.0 / NULLIF(SUM(traffic), 0), 2) AS cof_conversion_shop,
    ROUND(SUM(turnover) * 1.0 / NULLIF(SUM(bills_cnt), 0), 1) AS avg_check,
    ROUND(SUM(turnover) * 1.0 / NULLIF(SUM(traffic), 0), 1) AS rev_per_visitor
FROM retail_dwh.retail_daily
GROUP BY plant, shop_name
ORDER BY plant;


SELECT 
    plant AS "Код магазина",
    shop_name AS "Название магазина",
    ROUND(SUM("Оборот"), 2) AS "Общий оборот", 
    ROUND(SUM("Скидки по купонам"), 2) AS "Общие скидки по купонам",
    ROUND(SUM("Оборот с учетом скидки"), 2) AS "Общий оборот с учетом скидки", 
    SUM("Количество проданных товаров") AS "Общее количество проданных товаров", 
    SUM("Количество чеков") AS "Общее количество чеков", 
    SUM("Трафик") AS "Общий трафик", 
    SUM("Количество товаров по акции") AS "Общее количество товаров по акции", 
    ROUND(SUM("Количество товаров по акции") * 100.0 / NULLIF(SUM("Количество проданных товаров"), 0), 1) AS "Доля товаров со скидкой, %", 
    ROUND(SUM("Количество проданных товаров") * 1.0 / NULLIF(SUM("Количество чеков"), 0), 2) AS "Среднее количество товаров в чеке",
    ROUND(SUM("Количество чеков") * 100.0 / NULLIF(SUM("Трафик"), 0), 2) AS "Коэффициент конверсии магазина, %",
    ROUND(SUM("Оборот") * 1.0 / NULLIF(SUM("Количество чеков"), 0), 1) AS "Средний чек, руб.",
    ROUND(SUM("Оборот") * 1.0 / NULLIF(SUM("Трафик"), 0), 1) AS "Средняя выручка на одного посетителя, руб."
FROM retail_dwh.retail_daily_distr
GROUP BY plant, shop_name
ORDER BY plant;
