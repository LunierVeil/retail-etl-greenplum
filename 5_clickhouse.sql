
-- 206 хост 
create table retail_dwh.retail_daily_ext (
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
	cof_convertion_shop Float64,
	avg_check Float64,
	rev_per_visitor Float64
)
engine=PostgreSQL(
	'192.168.214.203:5432',
    'adb',
    'retail_daily',
    'retail_dwh',
    'apEeZwS9ycnXBW5d',
    'retail_dwh'
);
SELECT count() FROM retail_dwh.retail_daily_ext;
create table retail_dwh.retail_daily_local (
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
	cof_convertion_shop Float64,
	avg_check Float64,
	rev_per_visitor Float64
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/retail_dwh/retail_daily/shard_1',
    'replica_1'
)
PARTITION BY toYYYYMM(dt)
ORDER BY (dt, plant);

CREATE TABLE retail_dwh.retail_daily_distr (
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
	cof_convertion_shop Float64,
	avg_check Float64,
	rev_per_visitor Float64
)
ENGINE = Distributed(
    'default_cluster',
    'retail_dwh',
    'retail_daily_local',
    cityHash64(plant)
);

SHOW TABLES FROM retail_dwh;


-- очистка 
ALTER TABLE retail_dwh.retail_daily_local
ON CLUSTER default_cluster 
DELETE WHERE dt >= '2021-01-01' AND dt < '2021-03-01';

-- вставка данных 
INSERT INTO retail_dwh.retail_daily_distr
SELECT * FROM retail_dwh.retail_daily_ext
WHERE dt >= '2021-01-01' AND dt < '2021-03-01';

SELECT count() FROM retail_dwh.retail_daily_distr;

--209 хост 

create table retail_dwh.retail_daily_local (
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
	cof_convertion_shop Float64,
	avg_check Float64,
	rev_per_visitor Float64
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/retail_dwh/retail_daily/shard_1',
    'replica_2'
)
PARTITION BY toYYYYMM(dt)
ORDER BY (dt, plant);
SELECT count() FROM retail_dwh.retail_daily_local;

--210 хост 
create table retail_dwh.retail_daily_local (
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
	cof_convertion_shop Float64,
	avg_check Float64,
	rev_per_visitor Float64
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/retail_dwh/retail_daily/shard_2',
    'replica_1'
)
PARTITION BY toYYYYMM(dt)
ORDER BY (dt, plant);
SELECT count() FROM retail_dwh.retail_daily_local;

--211 хост 
create table retail_dwh.retail_daily_local (
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
	cof_convertion_shop Float64,
	avg_check Float64,
	rev_per_visitor Float64
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/retail_dwh/retail_daily/shard_2',
    'replica_2'
)
PARTITION BY toYYYYMM(dt)
ORDER BY (dt, plant);
SELECT count() FROM retail_dwh.retail_daily_local;
