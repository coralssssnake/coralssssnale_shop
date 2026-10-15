# Семинар 5. dbt: первый аналитический слой интернет-магазина

Это стартовый проект сквозного проекта курса. Сегодня на семинаре вы соберёте в dbt цепочку **staging → intermediate → marts** для заказов интернет-магазина и покроете её тестами. Домашнее задание продолжает этот же репозиторий: [HOMEWORK.md](HOMEWORK.md).

## Бизнесовая задача

Отдел аналитики устал от того, что «выручку» каждый считает своим запросом. Нужна одна витрина заказов `fct_orders`, в которой правило подтверждённой покупки записано один раз, проверено тестами и описано в документации.

Правило из практики 2 не меняется: **подтверждённая покупка** — заказ со статусом `paid` и хотя бы одной успешной оплатой. Возврат в источнике записан успешной операцией с отрицательной суммой. Его нельзя считать оплатой.

## Что лежит в репозитории

| Путь | Что это |
|---|---|
| `compose.yaml`, `Dockerfile`, `init/01_init.sql` | Стенд: PostgreSQL с данными магазина и контейнер с dbt |
| `dbt_project.yml` | Настройки проекта: схема и материализация для каждого слоя |
| `profiles.yml` | Подключение dbt к базе |
| `models/staging/shop/_shop__sources.yml` | Описание источников: таблицы OLTP-базы. **Готово** |
| `models/staging/shop/stg_shop__orders.sql` | Пример staging-модели. **Готово** |
| `models/staging/shop/stg_shop__*.sql` | Остальные staging-модели с пропусками `TODO` |
| `models/intermediate/int_orders_with_payments.sql` | Заказ с итогами по платежам, с пропусками `TODO` |
| `models/marts/fct_orders.sql` | Витрина заказов с пропуском `TODO` |
| `tests/assert_no_negative_payments.sql` | Singular-тест из лекции |

Места `TODO` нужно дописать. Пока они не заполнены, модель падает с ошибкой `column "todo" does not exist`. Так и задумано.

## 0. Подготовка стенда (10 мин)

Нужны Docker Desktop, Git и DBeaver. Устанавливать Python и dbt не нужно: dbt работает в контейнере. **Подробная инструкция по установке и решению проблем — [SETUP.md](SETUP.md).** Сделайте её шаги до семинара.

```bash
git clone <ссылка на репозиторий>
cd store
docker compose up -d postgres
docker compose build dbt          # первый раз 1–3 минуты: в образ ставится dbt
```

Для краткости все команды dbt ниже записаны как `dbt …`. Полная форма — `docker compose run --rm dbt …`. На macOS и Linux можно один раз задать сокращение:

```bash
alias dbt="docker compose run --rm dbt"
```

В Windows (PowerShell) пишите полную форму команды.

Подключение DBeaver к той же базе:

| Параметр | Значение |
|---|---|
| Хост | `localhost` |
| Порт | `5436` |
| База | `shop` |
| Пользователь / пароль | `student` / `studentpass` |

Если порт `5436` занят, запустите `PG_PORT=5546 docker compose up -d postgres` и укажите этот порт в DBeaver. Сам dbt ходит в базу внутри Docker-сети, поэтому для него порт менять не нужно.

<details>
<summary>Запуск без Docker (по желанию)</summary>

Нужен Python 3.10–3.13: на Python 3.14 dbt пока не запускается.

```bash
python3.12 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
dbt debug                          # profiles.yml возьмётся из текущей папки
```
</details>

## 1. Первый запуск (10 мин)

| Шаг | Команда | Что должно получиться |
|---|---|---|
| Проверить подключение | `dbt debug` | В конце `All checks passed!` |
| Собрать готовую модель | `dbt run -s stg_shop__orders` | `OK created sql view model analytics_staging.stg_shop__orders` |
| Найти её в базе | DBeaver → `shop` → схема `analytics_staging` | Представление `stg_shop__orders`, 141 строка |
| Увидеть, что dbt отправил в базу | откройте `target/compiled/dbt_shop/models/staging/shop/stg_shop__orders.sql` | Вместо `{{ source('shop', 'orders') }}` стоит `"shop"."public"."orders"` |

Вопросы себе: почему модель стала **view**, а не таблицей? Где это задано? Подсказка: `dbt_project.yml`.

## 2. Staging-модели (20 мин)

Заполните `TODO` в трёх файлах. Staging — это «одна таблица источника → одна модель». Здесь нет JOIN-ов и агрегаций: только имена, типы и простые вычисления в пределах одной строки.

| Модель | Что дописать |
|---|---|
| `stg_shop__customers` | `registration_date` — дата регистрации без времени |
| `stg_shop__order_items` | `order_item_id` — ключ вида `101-1`; `gross_amount` — сумма до скидки; `line_amount` — после скидки |
| `stg_shop__payments` | `is_refund` — `true` для возврата: успешная операция с отрицательной суммой |

Запуск: `dbt run -s staging` собирает всю папку `models/staging`. В схеме `analytics_staging` должно быть 4 представления.

## 3. Тесты (20 мин)

Тест в dbt — это запрос, который ищет «плохие» строки. Вернул 0 строк — тест пройден.

**3.1. Generic-тесты.** В `models/staging/shop/_shop__models.yml` допишите тесты по образцу `stg_shop__orders`:

- `unique` и `not_null` на ключ каждой модели: `customer_id`, `order_item_id`, `payment_id`;
- `relationships`: `stg_shop__orders.customer_id` → `stg_shop__customers`, `order_id` в позициях и платежах → `stg_shop__orders`;
- `accepted_values` для `payment_status`: `success`, `failed`, `pending`;
- `accepted_values` для `order_status`. По документации OLTP-команды статусов четыре: `paid`, `pending`, `returned`, `cancelled`.

Синтаксис `relationships` и `accepted_values` в dbt 1.10:

```yaml
      - name: customer_id
        data_tests:
          - relationships:
              arguments:
                to: ref('stg_shop__customers')
                field: customer_id
      - name: payment_status
        data_tests:
          - accepted_values:
              arguments:
                values: ['success', 'failed', 'pending']
```

Запустите `dbt test -s staging`.

**3.2. Разберите упавшие тесты.** Два теста упадут, это часть задания. Для каждого ответьте: ошибка в данных или в нашем представлении о данных? Что исправить: данные, модель или тест?

«Плохие» строки каждого упавшего теста dbt сохраняет в схему `analytics_dbt_test__audit`. Готовый запрос для просмотра печатается в выводе после строки `See test failures:` — скопируйте его в DBeaver. SQL самого теста лежит в `target/compiled/dbt_shop/models/…` (generic) и `target/compiled/dbt_shop/tests/…` (singular).

**3.3. Singular-тест.** Тест из лекции «платёж не может быть отрицательным» нашим данным не подходит. Удалите его и напишите вместо него `tests/assert_refunds_only_for_returned_orders.sql`: возврат допустим только у заказа со статусом `returned`. Тест должен проходить.

## 4. Intermediate и первая витрина (20 мин)

**4.1.** Заполните `models/intermediate/int_orders_with_payments.sql`. Логику вы уже писали в практике 2. Сначала сверните платежи до одной строки на заказ, потом присоедините их к заказам. Обратный порядок размножит заказы с несколькими платежами.

**4.2.** В `models/marts/fct_orders.sql` исключите тестовые заказы.

**4.3.** Создайте `models/marts/_marts__models.yml`: описание `fct_orders`, тесты `unique` и `not_null` для `order_id`, `not_null` для `is_confirmed`.

Затем выполните `dbt build`: dbt соберёт модели и тут же их протестирует. Ошибку можно разобрать до конца: если упал тест в staging, зависимые модели получат статус `SKIP`.

## 5. Документация (10 мин)

Допишите `description` для моделей и ключевых колонок, затем:

```bash
dbt docs generate
docker compose run --rm --service-ports dbt docs serve --host 0.0.0.0 --port 8080 --no-browser
```

Откройте http://localhost:8080. В правом нижнем углу есть кнопка графа зависимостей (lineage). Найдите на графе путь от `source.shop.payments` до `fct_orders`. Остановить сервер: `Ctrl+C`.

## Бонус: Jinja

В CTE `order_payments` добавьте число операций в каждом статусе: `success_operations_count`, `failed_operations_count`, `pending_operations_count`. Пишите не три строки вручную, а цикл `{% for status in [...] %}`. Результат проверьте в `target/compiled/…`.

## Шпаргалка команд

| Команда | Что делает |
|---|---|
| `dbt run -s имя_модели` | Собрать одну модель |
| `dbt run -s staging` | Собрать все модели папки |
| `dbt run -s +fct_orders` | Собрать модель и всё, от чего она зависит |
| `dbt test -s имя_модели` | Прогнать тесты одной модели |
| `dbt build` | Собрать и протестировать всё в правильном порядке |
| `dbt compile -s имя_модели` | Только скомпилировать SQL в `target/compiled`, ничего не создавая |
| `dbt ls -s +fct_orders` | Показать, что попадёт в выборку |

## Самопроверка

| Проверка | Ожидаемый результат |
|---|---|
| Представления в `analytics_staging` | 4: `stg_shop__orders`, `stg_shop__customers`, `stg_shop__order_items`, `stg_shop__payments` |
| `accepted_values` для `order_status` с четырьмя статусами | Падает: найден 1 лишний статус |
| `assert_no_negative_payments` | Падает: 7 строк — это возвраты |
| `assert_refunds_only_for_returned_orders` | Проходит |
| Строки в `analytics_marts.fct_orders` | `135` (из 141 заказа исключены 6 тестовых) |
| Подтверждённые заказы / их сумма `order_amount` | `106` / `91 620,00` — как в практике 2 |
| Заказ `113` | `paid_amount = 400`, `order_amount = 200`, `successful_payments_count = 2` |
| Заказ `107` | `returned`, `paid_amount = 700`, `refunded_amount = 700`, `net_paid_amount = 0` |
| Заказ `119` | `paid`, но `is_confirmed = false`: успешной оплаты нет |
| `dbt build` | `ERROR=0` |

Если подтверждённых заказов `107`, проверьте, требуете ли вы успешную оплату: у заказа `119` статус `paid`, но платежей нет. Если строк больше `135` или сумма больше `91 620,00`, проверьте зернистость: платежи нужно свернуть до заказа **до** JOIN.

## После семинара

Сохраните работу в своём репозитории: так начинается домашнее задание. Подробности — в [HOMEWORK.md](HOMEWORK.md).

```bash
git add .
git commit -m "Семинар 5: staging, int_orders_with_payments, fct_orders"
```
