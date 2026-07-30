--gpfdist
create external table retail_dwh.promo_types_ext(
	promotion_type text,
	type_name text
)
location('gpfdist://172.16.128.134:8080/promo_types.csv')
on all 
format 'csv' (delimiter ';' header )
encoding 'utf8';

create external table retail_dwh.store_ext(
	shop_id text,
	shop_name text
)
location('gpfdist://172.16.128.134:8080/store*.csv')
on all 
format 'csv' (delimiter ';' header )
encoding 'utf8';

DROP EXTERNAL TABLE retail_dwh.coupons_ext;
create external table retail_dwh.coupons_ext(
	shop_id text,
	calday date,
	coupon_number varchar(7),
	promo_id text,
	product_id int8,
	receipt_id int8
)
location('gpfdist://172.16.128.134:8080/coupons*.csv')
on all 
format 'csv' (delimiter ';' header )
encoding 'utf8';

create external table retail_dwh.promos_ext(
	promos_id text,
	names text,
	type_promos int4,
	product int8,
	discount_amount int4
)
location('gpfdist://172.16.128.134:8080/promos*.csv')
on all 
format 'csv' (delimiter ';' header )
encoding 'utf8';


--pxf
CREATE EXTERNAL table retail_dwh.traffic_ext(
	plant bpchar(4),
	"date" bpchar(10),
	"time" bpchar(6),
	frame_id bpchar(10),
	quantity int4 
)
location ('pxf://gp.traffic?PROFILE=JDBC&JDBC_DRIVER=org.postgresql.Driver&DB_URL=jdbc:postgresql://192.168.214.212:5432/postgres&USER=intern&PASS=intern'
) on all
FORMAT 'CUSTOM' (FORMATTER='pxfwritable_import')
encoding 'UTF8';

CREATE EXTERNAL table retail_dwh.bills_head_ext(
	billnum int8,
	plant bpchar(4),
	calday date
)
location ('pxf://gp.bills_head?PROFILE=JDBC&JDBC_DRIVER=org.postgresql.Driver&DB_URL=jdbc:postgresql://192.168.214.212:5432/postgres&USER=intern&PASS=intern'
) on all
FORMAT 'CUSTOM' (FORMATTER='pxfwritable_import')
encoding 'UTF8';

CREATE EXTERNAL table retail_dwh.bills_item_ext(
	billnum int8,
	billitem int8,
	material int8,
	qty int8,
	netval numeric(17, 2),
	tax numeric(17, 2),
	rpa_sat numeric(17, 2),
	calday date 
)
location ('pxf://gp.bills_item?PROFILE=JDBC&JDBC_DRIVER=org.postgresql.Driver&DB_URL=jdbc:postgresql://192.168.214.212:5432/postgres&USER=intern&PASS=intern'
) on all
FORMAT 'CUSTOM' (FORMATTER='pxfwritable_import')
encoding 'UTF8';
