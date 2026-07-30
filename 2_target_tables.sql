-- начало
CREATE SCHEMA retail_dwh;
-- проверка
SELECT * FROM retail_dwh.promo_types_ext;
SELECT * FROM retail_dwh.store_ext;
SELECT * FROM retail_dwh.coupons_ext;
SELECT * FROM retail_dwh.promos_ext;
SELECT * FROM retail_dwh.traffic_ext LIMIT 3;
SELECT * FROM retail_dwh.bills_head_ext LIMIT 3;
SELECT * FROM retail_dwh.bills_item_ext LIMIT 3;
-- справочники
create table retail_dwh.promo_types(
	promotion_type text not null,
	type_name text not null
)
distributed replicated;

create table retail_dwh.stores(
	shop_id text not null,
	shop_name text not null
)
distributed replicated;

create table retail_dwh.promos(
	promos_id text not null,
	names text NOT NULL,
	type_promos int4 not null,
	product int8 not null,
	discount_amount int4 not null
)
distributed replicated;
--факты
--AO
create table retail_dwh.coupons(
    shop_id text NOT NULL,
    calday date NOT NULL,
    coupon_number varchar(7),
    promo_id text NOT NULL,
    product_id int8 NOT NULL,
    receipt_id int8 NOT NULL
)
with(
    appendonly=true,
    orientation=column,
    compresstype=zstd,
    compresslevel=1
)
distributed by(shop_id, calday)
partition by range (calday)
(
   start ('2021-01-01') inclusive
   end ('2025-01-01') exclusive
   every (interval '1 month'),
   DEFAULT PARTITION other
);

create table retail_dwh.traffic(
	plant bpchar(4) NOT NULL,
	calday date NOT NULL,
	caltime bpchar(6) NOT  NULL,
	frame_id bpchar(10) NOT  NULL,
	quantity int4 NOT NULL
)
with(
appendonly=true,
orientation=column,
compresstype=zstd,
compresslevel=1
)
distributed by(plant,calday)
partition  by range (calday)
(
   start ('2021-01-01') inclusive
    end ('2025-01-01') exclusive
    every (interval '1 month'),
    DEFAULT PARTITION other
);


create table retail_dwh.bills_head(
	billnum int8 NOT NULL,
	plant bpchar(4) NOT NULL,
	calday date NOT NULL
)
with(
appendonly=true,
orientation=column,
compresstype=zstd,
compresslevel=1
)
distributed by(plant,calday)
partition  by range (calday)
(
   start ('2021-01-01') inclusive
    end ('2025-01-01') exclusive
    every (interval '1 month'),
    DEFAULT PARTITION other
);
create table retail_dwh.bills_item(
	billnum int8 NOT NULL,
	billitem int8 NOT NULL,
	material int8 NOT NULL,
	qty int8 NOT NULL,
	netval numeric(17, 2) NOT NULL,
	tax numeric(17, 2) NOT NULL,
	rpa_sat numeric(17, 2) NOT NULL,
	calday date NOT NULL
)
with(
appendonly=true,
orientation=column,
compresstype=zstd,
compresslevel=1
)
distributed by(billnum,billitem)
partition  by range (calday)
(
   start ('2021-01-01') inclusive
    end ('2025-01-01') exclusive
    every (interval '1 month'),
    DEFAULT PARTITION other
);




