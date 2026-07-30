# Retail ETL Pipeline

ETL-пайплайн для формирования витрины розничных продаж на базе Greenplum, ClickHouse, Airflow и Superset.

## Стек

- **Greenplum** — хранение и обработка данных (MPP)
- **ClickHouse** — аналитическое хранилище
- **Apache Airflow** — автоматизация пайплайна
- **Apache Superset** — визуализация

## Архитектура

Данные загружаются из CSV через `gpfdist` и из PostgreSQL через `PXF/JDBC` во внешние таблицы Greenplum.

Хранилище в Greenplum:
- справочники — `HEAP`, `REPLICATED`
- таблицы фактов — `AO` (column-oriented, компрессия `zstd`), партиционирование по дате

На основе таблиц фактов строится витрина `v_retail_daily` (SQL-запрос на 9 CTE). Данные витрины сверены с эталонным Excel-отчётом.

Витрина переносится в кластер ClickHouse (2 шарда × 2 реплики, `ReplicatedMergeTree` + `Distributed`-таблица) и визуализируется в Superset-дашборде с фильтрами по дате и магазину.

Весь процесс автоматизирован через Airflow DAG с TaskGroup, зависимостями между шагами и валидацией результата.

## Структура

- `1_external_tables.sql` — внешние таблицы (gpfdist, PXF)
- `2_target_tables.sql` — целевые таблицы (справочники + AO-таблицы фактов с партиционированием)
- `3_load_functions.sql` — функции загрузки (full load, delta по партициям)
- `4_datamart.sql` — функция построения витрины данных (9 CTE)
- `5_clickhouse.sql` — таблицы и загрузка в ClickHouse (ReplicatedMergeTree + Distributed)
- `6_dag.py` — Airflow DAG (TaskGroup, зависимости, валидация)
- `7_validation.sql` — сверка агрегированных метрик с эталонным Excel-отчётом

## Метрики витрины

Оборот, скидки по купонам, количество чеков, трафик, коэффициент конверсии, средний чек и др.
