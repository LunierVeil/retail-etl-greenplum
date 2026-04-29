-- импорт представления
CREATE TABLE std16_12fp.v_retail_daily_ext 
(
    dt Date,
    plant String,
    shop_name String,
    turnover Float64,
    coupon_discount Float64,
    net_turnover Float64,
    sold_qty Int64,
    bills_cnt Int64,
    traffic Int64,
    promo_qty Int64,
    share_discount_pct Float64,
    avg_product Float64,
    cof_conversion_shop Float64,
    avg_check Float64,
    rev_per_visitor Float64
)
ENGINE = PostgreSQL(
    '192.168.214.203:5432',
    'adb',
    'v_retail_daily',
    'std16_12',
    'dHG4gTEg0Z8eVnAT',
    'std16_12fp'
);

-- создания реплик
DROP TABLE std16_12fp.retail_daily_local;

CREATE TABLE std16_12fp.retail_daily_local (
    dt                  Date,
    plant               String,
    shop_name           String,
    turnover            Float64,
    coupon_discount     Float64,
    net_turnover        Float64,
    sold_qty            Int64,
    bills_cnt           Int64,
    traffic             Int64,
    promo_qty           Int64,
    share_discount_pct  Float64,
    avg_product         Float64,
    cof_conversion_shop Float64,
    avg_check           Float64,
    rev_per_visitor     Float64
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/std16_12fp/retail_daily_v2/shard_1',
    'replica_1'   
)
PARTITION BY toYYYYMM(dt)
ORDER BY (dt,plant);



--Проверим, что движок встал правильно
SELECT engine, create_table_query 
FROM system.tables 
WHERE database = 'std16_12fp' AND name = 'retail_daily_local';

-- Проверим статус репликации
SELECT is_readonly, queue_size, future_parts, absolute_delay
FROM system.replicas 
WHERE database = 'std16_12fp' AND table = 'retail_daily_local';
--Тестовая вставка + проверка
INSERT INTO std16_12fp.retail_daily_local 
SELECT * FROM std16_12fp.v_retail_daily_ext LIMIT 10;
-- имя кластера
SELECT cluster FROM system.clusters LIMIT 1;
-- создания дистрибуции
DROP TABLE IF EXISTS std16_12fp.retail_daily_distr;
CREATE TABLE std16_12fp.retail_daily_distr
(
    dt Date,
    plant String,
    shop_name String,
    turnover Float64,
    coupon_discount Float64,
    net_turnover Float64,
    sold_qty Int64,
    bills_cnt Int64,
    traffic Int64,
    promo_qty Int64,
    share_discount_pct Float64,
    avg_product Float64,
    cof_conversion_shop Float64,
    avg_check Float64,
    rev_per_visitor Float64
)
ENGINE = Distributed(
    'default_cluster',
    'std16_12fp',
    'retail_daily_local',
    cityHash64(plant)
);
-- заливаем данные
INSERT INTO std16_12fp.retail_daily_distr
SELECT * FROM std16_12fp.v_retail_daily_ext;
-- проверка общего
SELECT count() FROM std16_12fp.retail_daily_distr;
-- проверка по шардам
SELECT count() FROM std16_12fp.retail_daily_local;
-- в ClickHouse
SELECT plant, sum(turnover) as turnover
FROM std16_12fp.retail_daily_distr
GROUP BY plant
ORDER BY plant;
--в gp
select plant, sum(turnover) as turnover
FROM std16_12fp.v_retail_daily_ext 
GROUP BY plant
ORDER BY plant;

-- на хосте 209
CREATE DATABASE std16_12fp;
DROP TABLE std16_12fp.retail_daily_local;
CREATE TABLE std16_12fp.retail_daily_local (
    dt                  Date,
    plant               String,
    shop_name           String,
    turnover            Float64,
    coupon_discount     Float64,
    net_turnover        Float64,
    sold_qty            Int64,
    bills_cnt           Int64,
    traffic             Int64,
    promo_qty           Int64,
    share_discount_pct  Float64,
    avg_product         Float64,
    cof_conversion_shop Float64,
    avg_check           Float64,
    rev_per_visitor     Float64
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/std16_12fp/retail_daily_v2/shard_1',
    'replica_2'   
)
PARTITION BY toYYYYMM(dt)
ORDER BY (dt,plant);

SELECT count() FROM std16_12fp.retail_daily_local;
-- на хосте 210
CREATE DATABASE std16_12fp;

DROP TABLE std16_12fp.retail_daily_local;
CREATE TABLE std16_12fp.retail_daily_local (
    dt                  Date,
    plant               String,
    shop_name           String,
    turnover            Float64,
    coupon_discount     Float64,
    net_turnover        Float64,
    sold_qty            Int64,
    bills_cnt           Int64,
    traffic             Int64,
    promo_qty           Int64,
    share_discount_pct  Float64,
    avg_product         Float64,
    cof_conversion_shop Float64,
    avg_check           Float64,
    rev_per_visitor     Float64
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/std16_12fp/retail_daily_v2/shard_2',
    'replica_1'   
)
PARTITION BY toYYYYMM(dt)
ORDER BY (dt,plant);

SELECT engine FROM system.tables WHERE database = 'std16_12fp' AND name = 'retail_daily_local';


SELECT count() FROM std16_12fp.retail_daily_local;

SELECT shard_num, replica_num, host_name, port
FROM system.clusters
WHERE cluster = 'default_cluster';
-- на хосте 211
CREATE DATABASE std16_12fp;

DROP TABLE std16_12fp.retail_daily_local;
CREATE TABLE std16_12fp.retail_daily_local (
    dt                  Date,
    plant               String,
    shop_name           String,
    turnover            Float64,
    coupon_discount     Float64,
    net_turnover        Float64,
    sold_qty            Int64,
    bills_cnt           Int64,
    traffic             Int64,
    promo_qty           Int64,
    share_discount_pct  Float64,
    avg_product         Float64,
    cof_conversion_shop Float64,
    avg_check           Float64,
    rev_per_visitor     Float64
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/std16_12fp/retail_daily_v2/shard_2',
    'replica_2'   
)
PARTITION BY toYYYYMM(dt)
ORDER BY (dt,plant);

SELECT engine FROM system.tables WHERE database = 'std16_12fp' AND name = 'retail_daily_local';

SELECT count() FROM std16_12fp.retail_daily_local;

SELECT shard_num, replica_num, host_name, port
FROM system.clusters
WHERE cluster = 'default_cluster';