with source as (
    select * from {{ source('shop', 'products') }}
)

select
    product_id,
    product_name,
    brand,
    category
from source