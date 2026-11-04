{% docs __overview__ %}

Аналитический слой интернет-магазина

Звезда: факты `fct_orders`, `fct_order_items`; измерения `dim_customers`, `dim_products`, `dim_dates`.

Слои: `staging` (view) -> `intermediate` (view) -> `marts` (table, Greenplum).

Бизнес-вопросы: выручка по месяцам и категориям, доля покупателей по каналам, средний чек по городам, бренды с возвратами.

{% enddocs %}

{% docs confirmed_order %}

Подтверждённый заказ — заказ со статусом `paid` и хотя бы одной *успешной* оплатой (`payment_status = 'success'`, `amount > 0`).

Возвраты (успешные операции с отрицательной суммой) не делают заказ неподтверждённым, но уменьшают `net_paid_amount`.

{% enddocs %}