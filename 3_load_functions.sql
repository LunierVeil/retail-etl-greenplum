CREATE OR REPLACE FUNCTION std16_12fp.f_full_load(p_target varchar, p_ext varchar)
RETURNS void
LANGUAGE plpgsql
VOLATILE
EXECUTE ON MASTER
AS $$
BEGIN
    execute format('truncate table std16_12fp.%I',p_target);
	execute format('insert into std16_12fp.%I select * from std16_12fp.%I',p_target,p_ext);
END;
$$;
-- справочники
promo_types
stores
promos

-- AO
coupons
traffic
bills_head
bills_item

select std16_12fp.f_full_load('promo_types','promo_types_ext');
select std16_12fp.f_full_load('stores','store_ext');
select std16_12fp.f_full_load('promos','promos_ext');

SELECT * FROM std16_12fp.promo_types;
select * from std16_12fp.stores;
select * from std16_12fp.promos;

select * from std16_12fp.coupons_ext;
select * from std16_12fp.traffic_ext;
select * from std16_12fp.bills_head_ext;
select * from std16_12fp.bills_item_ext;


create or replace function std16_12fp.f_delta_partition_facts(
p_target varchar,
p_ext varchar,
p_date date
)
returns void 
language plpgsql
volatile
execute on master
as $$
declare
v_tmp_name text;
begin
v_tmp_name := 'tmp_fact_' || to_char(p_date,'YYYYMMDD');
	execute format('create table %I (like std16_12fp.%I)',v_tmp_name,p_target);
	
	execute format('insert into %I 
					select * from std16_12fp.%I
					where calday >= %L and calday < (%L::date + interval ''1 month'')
					',v_tmp_name,p_ext,p_date,p_date);
	     EXECUTE format(
            'ALTER TABLE std16_12fp.%I
             exchange partition for (%L) with table %I',
            p_target,p_date, v_tmp_name
        );
	execute format ('drop table if exists %I ',v_tmp_name);
end;
$$;


SELECT std16_12fp.f_delta_partition_facts('bills_head', 'bills_head_ext', '2021-01-01');
SELECT std16_12fp.f_delta_partition_facts('bills_head', 'bills_head_ext', '2021-02-01');
SELECT std16_12fp.f_delta_partition_facts('bills_item', 'bills_item_ext', '2021-01-01');
SELECT std16_12fp.f_delta_partition_facts('bills_item', 'bills_item_ext', '2021-02-01');
SELECT std16_12fp.f_delta_partition_facts('coupons', 'coupons_ext', '2021-01-01');
SELECT std16_12fp.f_delta_partition_facts('coupons', 'coupons_ext', '2021-02-01');


SELECT gp_segment_id, count(*) 
FROM std16_12fp.bills_head 
GROUP BY gp_segment_id 
ORDER BY gp_segment_id;


SELECT gp_segment_id, count(*) 
FROM std16_12fp.bills_item
GROUP BY gp_segment_id 
ORDER BY gp_segment_id;

SELECT gp_segment_id, count(*) 
FROM std16_12fp.coupons
GROUP BY gp_segment_id 
ORDER BY gp_segment_id;


create or replace function std16_12fp.f_delta_partition_traffic(
p_target varchar,
p_ext varchar,
p_date date
)
returns void 
language plpgsql
volatile
execute on master
as $$
declare
v_tmp_name text;
begin
v_tmp_name := 'tmp_fact_' || to_char(p_date,'YYYYMMDD');
	execute format('create table %I (like std16_12fp.%I)',v_tmp_name,p_target);
	
	execute format('insert into %I 
					select plant, to_date("date", ''DD.MM.YYYY''), "time", frame_id, quantity from std16_12fp.%I
					where to_date("date", ''DD.MM.YYYY'') >= %L and to_date("date", ''DD.MM.YYYY'') < (%L::date + interval ''1 month'')
					',v_tmp_name,p_ext,p_date,p_date);
	     EXECUTE format(
            'ALTER TABLE std16_12fp.%I
             exchange partition for (%L) with table %I',
            p_target,p_date, v_tmp_name
        );
	execute format ('drop table if exists %I ',v_tmp_name);
end;
$$;
SELECT std16_12fp.f_delta_partition_traffic('traffic', 'traffic_ext', '2021-01-01');
SELECT std16_12fp.f_delta_partition_traffic('traffic', 'traffic_ext', '2021-02-01');
drop table std16_12fp.traffic;

select * from std16_12fp.traffic;
SELECT gp_segment_id, count(*) 
FROM std16_12fp.traffic
GROUP BY gp_segment_id 
ORDER BY gp_segment_id;

SELECT count(*) as trafic_table FROM std16_12fp.traffic;
SELECT count(*) as bills_head_table FROM std16_12fp.bills_head;
SELECT count(*) as bills_item_table FROM std16_12fp.bills_item;
SELECT count(*) as coupons_table FROM std16_12fp.coupons;
