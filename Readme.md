# Retail ETL Pipeline

ETL-пайплайн для формирования витрины розничных продаж.

## Стек
- Greenplum — хранение и обработка данных
- ClickHouse — аналитическое хранилище
- Apache Airflow — автоматизация
- Apache Superset — визуализация

## Архитектура
Данные загружаются из CSV (gpfdist) и PostgreSQL (PXF) в Greenplum.
Строится витрина v_retail_daily с гранулярностью день + магазин.
Витрина выгружается в ClickHouse и визуализируется в Superset.

## Структура
- `1_external_tables.sql` — внешние таблицы (gpfdist, PXF)
- `2_target_tables.sql` — целевые таблицы с партиционированием
- `3_load_functions.sql` — функции загрузки (full load, delta partition)
- `4_datamart.sql` — витрина данных
- `5_view.sql` — представление витрины
- `6_clickhouse.sql` — таблицы и загрузка в ClickHouse
- `7_dag.py` — Airflow DAG

## Метрики витрины
Оборот, скидки по купонам, количество чеков, трафик,
коэффициент конверсии, средний чек и др.
