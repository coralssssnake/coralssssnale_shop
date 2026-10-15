-- Задание 2. Staging позиций заказа: одна строка — один товар в заказе.
with source as (
    select * from {{ source('shop', 'order_items') }}
)

select
    -- Своего ключа у позиции нет: склейте order_id и product_id через дефис, например '101-1'.
    TODO                            as order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    discount_amount,
    TODO                            as gross_amount,   -- сумма до скидки
    TODO                            as line_amount     -- сумма после скидки
from source
