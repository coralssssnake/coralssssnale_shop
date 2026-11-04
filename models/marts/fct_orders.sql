-- Задание 4. Факт заказов: одна строка — один заказ. Тестовые заказы в витрину не попадают.
-- Материализация — table (задана для папки marts в dbt_project.yml).

with orders as (
    select * from {{ ref('int_orders_with_payments') }}
    where not is_test_order
),

items as (
    select 
        order_id, 
        count(distinct product_id) as items_count
    from {{ ref('stg_shop__order_items') }}
    group by order_id
)

select
    o.order_id,
    o.customer_id,
    o.order_date,
    o.ordered_at,
    o.order_status,
    o.order_amount,
    o.paid_amount,
    o.refunded_amount,
    o.net_paid_amount,
    o.successful_payments_count,
    o.first_paid_at,
    o.is_confirmed,
    coalesce(i.items_count, 0) as items_count
from orders o
left join items i on i.order_id = o.order_id
