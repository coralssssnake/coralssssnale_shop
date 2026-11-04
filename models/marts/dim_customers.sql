{{ config(
    materialized='table',
    distributed_replicated=true
) }}

with customers as (
    select * from {{ ref('stg_shop__customers') }}
),

confirmed as (
    select *
    from {{ ref('int_orders_with_payments') }}
    where is_confirmed and not is_test_order
),

first_order as (
    select distinct on (customer_id)
        customer_id,
        order_id   as first_confirmed_order_id,
        ordered_at as first_confirmed_at
    from confirmed
    order by customer_id, ordered_at, order_id
),

agg as (
    select
        customer_id,
        count(*)          as confirmed_orders_count,
        sum(order_amount) as confirmed_revenue
    from confirmed
    group by customer_id
)

select
    c.customer_id,
    c.registration_date,
    c.registered_at,
    c.city,
    c.acquisition_channel,
    f.first_confirmed_order_id,
    f.first_confirmed_at,
    coalesce(a.confirmed_orders_count, 0) as confirmed_orders_count,
    coalesce(a.confirmed_revenue, 0)      as confirmed_revenue,
    (coalesce(a.confirmed_orders_count, 0) > 0) as is_buyer
from customers c
left join first_order f on f.customer_id = c.customer_id
left join agg a         on a.customer_id = c.customer_id