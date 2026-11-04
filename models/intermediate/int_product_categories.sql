{{ config(materialized='view') }}

with recursive tree as (
    select
        category_id,
        parent_category_id,
        category_name,
        category_id   as root_category_id,
        category_name as root_category_name,
        null::text    as parent_category_name,
        category_name as full_path,
        1             as depth
    from {{ ref('stg_shop__product_categories') }}
    where parent_category_id is null

    union all

    select
        c.category_id,
        c.parent_category_id,
        c.category_name,
        t.root_category_id,
        t.root_category_name,
        t.category_name,
        t.full_path || ' > ' || c.category_name,
        t.depth + 1
    from {{ ref('stg_shop__product_categories') }} c
    join tree t on c.parent_category_id = t.category_id
)

select
    category_id,
    parent_category_id,
    category_name,
    root_category_id,
    root_category_name,
    parent_category_name,
    full_path,
    depth
from tree