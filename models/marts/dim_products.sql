{{ config(
    materialized='table',
    distributed_replicated=true
) }}

with products as (
    select * from {{ ref('stg_shop__products') }}
),
cats as (
    select * from {{ ref('int_product_categories') }}
)

select
    p.product_id,
    p.product_name,
    p.brand,
    c.category_id,
    c.category_name,
    c.parent_category_name,
    c.root_category_id,
    c.root_category_name,
    c.full_path
from products p
left join cats c on c.category_name = p.category