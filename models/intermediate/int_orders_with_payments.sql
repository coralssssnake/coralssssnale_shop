-- Задание 4. Одна строка — один заказ, к нему пристыкованы итоги по платежам.
-- Сначала сверните платежи до заказа (CTE order_payments), потом присоедините их к заказам.
with orders as (
    select * from {{ ref('stg_shop__orders') }}
),

payments as (
    select * from {{ ref('stg_shop__payments') }}
),

order_payments as (
    select
        order_id,
        TODO    as successful_payments_count,  -- успешные оплаты без возвратов
        TODO    as paid_amount,                -- их сумма; 0, если их нет
        TODO    as refunded_amount,            -- сумма возвратов положительным числом; 0, если их нет
        TODO    as first_paid_at               -- время первой успешной оплаты
    from payments
    group by order_id
)

select
    o.order_id,
    o.customer_id,
    o.ordered_at,
    o.order_date,
    o.order_status,
    o.order_amount,
    o.is_test_order,
    TODO    as successful_payments_count,   -- 0 вместо null
    TODO    as paid_amount,
    TODO    as refunded_amount,
    TODO    as net_paid_amount,             -- оплачено минус возвращено
    p.first_paid_at,
    TODO    as is_confirmed                 -- статус paid и хотя бы одна успешная оплата
from orders as o
TODO join order_payments as p
    on p.order_id = o.order_id
