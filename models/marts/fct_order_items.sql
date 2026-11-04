{{ config(
    materialized='incremental',
    unique_key='order_item_id',
    distributed_by='order_id',
    orientation='column',
    on_schema_change='sync_all_columns'
) }}

with items as (
    select * from {{ ref('stg_shop__order_items') }}
),

orders as (
    select order_id, order_date, ordered_at, is_confirmed, is_test_order
    from {{ ref('int_orders_with_payments') }}
)

select
    i.order_item_id,
    i.order_id,
    i.product_id,
    o.order_date,
    o.ordered_at,
    o.is_confirmed,
    i.quantity,
    i.unit_price,
    i.discount_amount,
    i.gross_amount,
    i.line_amount
from items i
join orders o on o.order_id = i.order_id
where not o.is_test_order
{% if is_incremental() %}
  and o.ordered_at > (select coalesce(max(ordered_at), '1900-01-01'::timestamp) from {{ this }})
{% endif %}