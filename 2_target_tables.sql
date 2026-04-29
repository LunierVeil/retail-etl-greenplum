-- начало
CREATE SCHEMA std16_12fp;
-- проверка
SELECT * FROM std16_12fp.promo_types_ext;
SELECT * FROM std16_12fp.store_ext;
SELECT * FROM std16_12fp.coupons_ext;
SELECT * FROM std16_12fp.promos_ext;
SELECT * FROM std16_12fp.traffic_ext LIMIT 3;
SELECT * FROM std16_12fp.bills_head_ext LIMIT 3;
SELECT * FROM std16_12fp.bills_item_ext LIMIT 3;
-- справочники
create table std16_12fp.promo_types(
	promotion_type text not null,
	type_name text not null
)
distributed replicated;

create table std16_12fp.stores(
	shop_id text not null,
	shop_name text not null
)
distributed replicated;

create table std16_12fp.promos(
	promos_id text not null,
	names text,
	type_promos int4 not null,
	product int8 not null,
	discount_amount int4 not null
)
distributed replicated;
--факты
--AO
create table std16_12fp.coupons(
	shop_id text not null,
	coupon_date date not null,
	coupon_number varchar(7),
	promo_id text,
	product_id int8 not null,
	receipt_id int8 not null
)
with(
appendonly=true,
orientation=column,
compresstype=zstd,
compresslevel=1
)
distributed by(receipt_id)
partition  by range (coupon_date)
(
   start ('2021-01-01') inclusive
    end ('2025-01-01') exclusive
    every (interval '1 month')
);

create table std16_12fp.traffic(
	plant bpchar(4) NULL,
	calday date NULL,
	caltime bpchar(6) NULL,
	frame_id bpchar(10) NULL,
	quantity int4 NULL
)
with(
appendonly=true,
orientation=column,
compresstype=zstd,
compresslevel=1
)
distributed by(plant,frame_id)
partition  by range (calday)
(
   start ('2021-01-01') inclusive
    end ('2025-01-01') exclusive
    every (interval '1 month')
);


create table std16_12fp.bills_head(
	billnum int8 NULL,
	plant bpchar(4) NULL,
	calday date NULL
)
with(
appendonly=true,
orientation=column,
compresstype=zstd,
compresslevel=1
)
distributed by(billnum)
partition  by range (calday)
(
   start ('2021-01-01') inclusive
    end ('2025-01-01') exclusive
    every (interval '1 month')
);
create table std16_12fp.bills_item(
	billnum int8 NULL,
	billitem int8 NULL,
	material int8 NULL,
	qty int8 NULL,
	netval numeric(17, 2) NULL,
	tax numeric(17, 2) NULL,
	rpa_sat numeric(17, 2) NULL,
	calday date NULL
)
with(
appendonly=true,
orientation=column,
compresstype=zstd,
compresslevel=1
)
distributed by(billnum)
partition  by range (calday)
(
   start ('2021-01-01') inclusive
    end ('2025-01-01') exclusive
    every (interval '1 month')
);




