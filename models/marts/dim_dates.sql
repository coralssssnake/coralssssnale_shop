{{ config(
    materialized='table',
    distributed_replicated=true
) }}

with bounds as (
    select
        min(order_date) as min_date,
        max(order_date) as max_date
    from {{ ref('stg_shop__orders') }}
),

spine as (
    select generate_series(min_date, max_date, interval '1 day')::date as date_day
    from bounds
)

select
    date_day,
    extract(year from date_day)::int as year,
    extract(quarter from date_day)::int as quarter,
    extract(month from date_day)::int as month,
    extract(day from date_day)::int as day_of_month,
    extract(isodow  from date_day)::int as day_of_week,
    (extract(isodow from date_day) in (6, 7))  as is_weekend
from spine