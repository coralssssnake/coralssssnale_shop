-- Задание 2. Staging клиентов: одна строка — один клиент.
-- Возьмите все колонки источника и добавьте дату регистрации без времени.
with source as (
    select * from {{ source('shop', 'customers') }}
)

select
    customer_id,
    registered_at,
    registered_at::date                            as registration_date,  -- дата без времени
    city,
    acquisition_channel
from source
