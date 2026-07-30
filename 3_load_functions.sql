-- справочники
CREATE OR REPLACE FUNCTION retail_dwh.f_full_load(p_target varchar, p_ext varchar)
RETURNS void
LANGUAGE plpgsql
VOLATILE
EXECUTE ON MASTER
AS $$
DECLARE
	v_count bigint;
BEGIN
 	-- проверка
	execute format('select count(*) from retail_dwh.%I',p_ext) into v_count;
	if v_count = 0 then
		raise exception 'source table is empty!';
	end if;
	-- вставка + делит
	execute format('truncate table retail_dwh.%I', p_target);

	execute format('insert into retail_dwh.%I select * from retail_dwh.%I ', p_target ,p_ext);
	
	-- статистика
	execute format('analyze retail_dwh.%I', p_target);
	
	exception
		when others then
				raise exception 'Error in full load table %: %',p_target,SQLERRM; 

END;
$$;
SELECT retail_dwh.f_full_load('promo_types', 'promo_types_ext');
SELECT retail_dwh.f_full_load('stores', 'store_ext');
SELECT retail_dwh.f_full_load('promos', 'promos_ext');

-- создания представления для трафика
create or replace view retail_dwh.traffic_ext_view as
select
	plant,
	to_date("date",'DD.MM.YYYY') as calday,
	"time" as caltime,
	frame_id,
	quantity
	from retail_dwh.traffic_ext;
SELECT * FROM retail_dwh.traffic_ext_view;

create or replace function retail_dwh.f_delta_partition(
p_target varchar,
p_ext varchar,
p_date date
)
RETURNS void
LANGUAGE plpgsql
AS $$
declare
	v_tmp_name text;
begin
	v_tmp_name :='tmp_'|| p_target || '_' || to_char(p_date, 'YYYYMMDD') ;

	execute format('drop table if exists %I', v_tmp_name);

	execute format('create table %I (like retail_dwh.%I)',v_tmp_name,p_target);

	execute format('insert into %I 
					select * from retail_dwh.%I
					where calday >= %L::date  and calday < (%L::date + interval ''1 month'') ',v_tmp_name,p_ext,p_date,p_date);

	execute format ('	alter table retail_dwh.%I
						exchange partition for (%L ) 
						with table %I',p_target,p_date,v_tmp_name);

	execute format ('drop table %I',v_tmp_name);
	
	execute format('analyze retail_dwh.%I', p_target);

	exception
		when others then
			raise exception 'Error in delta load table % for date %: %', p_target, p_date, SQLERRM;
end;
$$;
--01
SELECT retail_dwh.f_delta_partition('traffic', 'traffic_ext_view', '2021-01-01'::date);
SELECT retail_dwh.f_delta_partition('coupons', 'coupons_ext', '2021-01-01'::date);
SELECT retail_dwh.f_delta_partition('bills_head', 'bills_head_ext', '2021-01-01'::date);
SELECT retail_dwh.f_delta_partition('bills_item', 'bills_item_ext', '2021-01-01'::date);

--02
SELECT retail_dwh.f_delta_partition('bills_head', 'bills_head_ext', '2021-02-01'::date);
SELECT retail_dwh.f_delta_partition('bills_item', 'bills_item_ext', '2021-02-01'::date);
SELECT retail_dwh.f_delta_partition('traffic', 'traffic_ext_view', '2021-02-01'::date);
SELECT retail_dwh.f_delta_partition('coupons', 'coupons_ext', '2021-02-01'::date);
























