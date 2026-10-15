# Как запустить проект семинара: Git и Docker

Эта инструкция — от чистого компьютера до команды `All checks passed!`. Если у вас уже работают Git и Docker Desktop, переходите сразу к [шагу 3](#шаг-3-освободить-ресурсы-от-прошлых-стендов).

**Сделайте шаги 1–6 до семинара.** Сборка образа скачивает dbt из интернета, а на паре 25 человек одновременно на одном Wi-Fi будут ждать долго.

## Что получится

```text
ваш компьютер
├── Git     — скачивает проект с GitHub и сохраняет вашу работу
└── Docker  — запускает программы в контейнерах:
    ├── postgres  — рабочая (OLTP) база интернет-магазина, порт 5436
    ├── greenplum — хранилище, где лежит аналитический слой, порт 5440
    ├── loader    — при запуске копирует сырые таблицы из postgres в greenplum
    └── dbt       — строит витрины в greenplum
```

Устанавливать Python, PostgreSQL, Greenplum и dbt на компьютер **не нужно**: всё работает внутри Docker.

## Что понадобится

| Что | Зачем | Проверка |
|---|---|---|
| Git | Скачать проект и сдать домашку | `git --version` |
| Docker Desktop | Запустить базу и dbt | `docker compose version` |
| DBeaver | Смотреть таблицы в базе (уже есть с прошлых практик) | — |
| ~5 ГБ свободного места, 8 ГБ оперативной памяти и интернет | Скачать образы при первом запуске. Образ Greenplum (~2 ГБ) у вас уже есть, если запускали практику 3 | — |

Все команды ниже вводятся в терминале:

- **macOS** — программа «Терминал»;
- **Windows** — PowerShell (Пуск → «PowerShell») или Git Bash;
- **Linux** — любой терминал.

## Шаг 1. Установить Git

**macOS.** Выполните `git --version`. Если Git не установлен, macOS сама предложит поставить «инструменты разработчика». Согласитесь и подождите несколько минут.

**Windows.** Скачайте установщик с https://git-scm.com/download/win и пройдите установку, оставляя все настройки по умолчанию. Затем **закройте и снова откройте** PowerShell.

**Linux (Ubuntu/Debian).** `sudo apt install git`

Проверка: команда `git --version` печатает что-то вроде `git version 2.4x`.

## Шаг 2. Установить и запустить Docker Desktop

**macOS.** Скачайте Docker Desktop с https://www.docker.com/products/docker-desktop/. Выберите версию под свой процессор:

- **Apple Chip** — Mac на M1/M2/M3/M4;
- **Intel Chip** — более старые Mac.

Какой у вас процессор, видно в меню Apple (значок яблока в левом верхнем углу) → «Об этом Mac».

**Windows.** Скачайте Docker Desktop там же. При установке оставьте галочку **Use WSL 2**. Если установщик попросит обновить WSL, выполните в PowerShell **от имени администратора**:

```powershell
wsl --install
```

После этого перезагрузите компьютер.

**Linux.** Подойдёт Docker Desktop или Docker Engine с плагином `docker compose`: https://docs.docker.com/engine/install/. Чтобы не писать `sudo` перед каждой командой, выполните `sudo usermod -aG docker $USER` и перезайдите в систему.

**Запустите Docker Desktop.** Дождитесь, пока внизу слева появится зелёная надпись **Engine running**. Docker Desktop должен быть запущен каждый раз, когда вы работаете с проектом.

Проверка:

```bash
docker --version
docker compose version
docker run --rm hello-world
```

Последняя команда должна напечатать `Hello from Docker!`.

## Шаг 3. Освободить ресурсы от прошлых стендов

В нашем стенде свой Greenplum. Если ещё работает стенд практики 3 (Greenplum + ClickHouse), два Greenplum одновременно могут не поместиться в память. Остановите старый стенд, данные при этом сохранятся:

```bash
cd <папка практики 3>
docker compose down
```

Или посмотрите, что сейчас запущено, и остановите всё сразу:

```bash
docker ps
docker stop $(docker ps -q)      # macOS / Linux / Git Bash
```

В PowerShell вместо последней команды используйте `docker ps -q | ForEach-Object { docker stop $_ }`.

## Шаг 4. Скачать проект

Перейдите в папку, где будете хранить учебные проекты. Надёжнее выбрать путь **без пробелов и кириллицы**, например `C:\study` или `~/study`:

```bash
mkdir study
cd study
git clone https://github.com/RKurbanova/store.git
cd store
```

Появится папка `store` со всеми файлами проекта. **Все дальнейшие команды выполняются из этой папки.** Если терминал закрыли, вернитесь в неё: `cd study/store`. Проверить, где вы находитесь, можно командой `pwd` (на Windows — `cd` без аргументов). В папке должен лежать файл `compose.yaml`.

## Шаг 5. Запустить базы и загрузить данные в хранилище

```bash
docker compose up -d
```

Команда запускает PostgreSQL и Greenplum, а когда обе базы готовы — сервис `loader`. Он копирует сырые таблицы магазина в Greenplum и завершается. При первом запуске скачиваются образы, это займёт несколько минут. Затем проверьте результат загрузки:

```bash
docker compose logs loader
```

Повторяйте команду, пока в конце не появится:

```text
loader-1  | Готово: в Greenplum, база dwh, схема raw загружено строк:
loader-1  | orders 141
loader-1  | order_items 444
loader-1  | payments 160
loader-1  | customers 40
```

Состояние контейнеров показывает `docker compose ps -a`. `postgres` и `greenplum` должны быть `Up … (healthy)`, `loader` — `Exited (0)`: он отработал и остановился, так и должно быть.

## Шаг 6. Собрать dbt и проверить подключение

```bash
docker compose build dbt
docker compose run --rm dbt debug
```

Сборка образа в первый раз занимает 1–3 минуты. Повторно она не нужна. В конце вывода `dbt debug` должно быть:

```text
All checks passed!
```

**Готово — к семинару вы подготовились.**

## Шаг 7. Подключить DBeaver

Создайте два подключения: **База данных → Новое соединение**. Тип — **PostgreSQL** для обоих: Greenplum понимает тот же протокол. Можно выбрать и тип Greenplum, если он есть в вашем DBeaver.

| Параметр | OLTP (PostgreSQL) | DWH (Greenplum) |
|---|---|---|
| Хост | `localhost` | `localhost` |
| Порт | **`5436`** | **`5440`** |
| База данных | `shop` | `dwh` |
| Пользователь | `student` | `gpadmin` |
| Пароль | `studentpass` | пустой |

Порты прошлых практик (5435, 5438, 5439) здесь не подходят.

Нажмите **Тест соединения** в каждом. В OLTP в схеме `public` должны быть таблицы `customers`, `orders`, `payments` и другие. В DWH в схеме `raw` должны быть их копии. Схемы `analytics_*` в DWH появятся после первого запуска dbt.

## Как писать команды dbt короче

Полная форма любой команды dbt — `docker compose run --rm dbt <команда>`. Например, `docker compose run --rm dbt run -s stg_shop__orders`. Можно один раз завести сокращение, и тогда писать просто `dbt run -s stg_shop__orders`.

**macOS / Linux / Git Bash:**

```bash
alias dbt="docker compose run --rm dbt"
```

**Windows PowerShell:**

```powershell
function dbt { docker compose run --rm dbt @args }
```

Сокращение действует, пока открыт этот терминал. В новом окне его нужно ввести снова.

## Каждый день: включить и выключить

| Что сделать | Команда |
|---|---|
| Начать работу | Запустить Docker Desktop, перейти в папку `store`, выполнить `docker compose up -d` |
| Закончить работу (данные сохранятся) | `docker compose down` |
| Заново загрузить сырые данные в Greenplum | `docker compose run --rm loader` |
| Начать с чистых баз (**удалит** все таблицы, которые построил dbt) | `docker compose down -v`, затем `docker compose up -d` |

Ваш код хранится в файлах в папке `store` и в Git, а не в базе. Поэтому `down -v` код не удаляет: после повторной загрузки следующий `dbt build` заново построит все витрины.

## Сохранять работу в Git

После каждого законченного задания:

```bash
git add .
git commit -m "что сделано, например: staging-модели"
```

Если Git попросит представиться (`Please tell me who you are`), выполните один раз:

```bash
git config --global user.name "Имя Фамилия"
git config --global user.email "ваша@почта"
```

Как отправить работу в свой репозиторий на GitHub, описано в [HOMEWORK.md](HOMEWORK.md#как-сдавать). GitHub не принимает обычный пароль при `git push`. Вместо него нужен токен: github.com → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token с галочкой `repo`. Токен вставляется в ответ на запрос `Password`. Ещё проще работать через программу GitHub Desktop.

## Если что-то не работает

| Сообщение | Причина | Что делать |
|---|---|---|
| `Cannot connect to the Docker daemon` / `error during connect` | Docker Desktop не запущен | Запустить и дождаться `Engine running` |
| `no configuration file provided: not found` | Команда выполнена не из папки `store` | `cd` в папку, где лежит `compose.yaml` |
| `port is already allocated` / `address already in use` | Порт 5436 или 5440 занят, например стендом прошлой практики | Остановить старый стенд (шаг 3) или задать другие порты: `PG_PORT=5546 GP_PORT=5540 docker compose up -d` (в PowerShell: `$env:PG_PORT=5546; $env:GP_PORT=5540; docker compose up -d`) и указать их в DBeaver. Для dbt менять ничего не нужно |
| `docker compose logs loader` пустой или нет строки «Готово» | Greenplum ещё запускается | Подождать минуту и повторить. Если `loader` в `docker compose ps -a` в состоянии `Exited (1)`, прочитать ошибку в логе и выполнить `docker compose run --rm loader` |
| `greenplum` долго не становится `healthy` или перезапускается | Не хватает памяти | Закрыть лишние программы и стенды, в Docker Desktop → Settings → Resources выделить не меньше 4 ГБ памяти |
| dbt: `relation "raw.orders" does not exist` | Данные не загружены в Greenplum | `docker compose run --rm loader` |
| `Bind for 0.0.0.0:8080 failed` при `docs serve` | Порт 8080 занят | Добавить `DOCS_PORT=8081` перед командой `docker compose run … docs serve …` (в PowerShell: `$env:DOCS_PORT=8081;` перед командой) и открыть http://localhost:8081. Саму команду менять не нужно |
| Сборка `docker compose build dbt` падает на `pip install` | Нет доступа к интернету или к PyPI | Проверить интернет, отключить VPN или прокси, повторить |
| `permission denied ... docker.sock` (Linux) | Пользователь не в группе `docker` | `sudo usermod -aG docker $USER` и перезайти |
| `WSL 2 installation is incomplete` (Windows) | Не установлен WSL | `wsl --install` от администратора, перезагрузка |
| `fatal: destination path 'store' already exists` | Проект уже скачан | Перейти в существующую папку: `cd store` |
| DBeaver: `password authentication failed` или нет таблиц | Подключение идёт к базе прошлой практики | Проверить порты: OLTP — **5436**, DWH — **5440** |
| `Could not connect to the database` в `dbt debug` | Greenplum ещё стартует | Подождать `(healthy)` в `docker compose ps` и повторить |
| dbt: `column "todo" does not exist` | В модели остались незаполненные `TODO` | Это нормально: заполните задание |
| Мало места на диске | Старые образы и тома | `docker system df` — посмотреть, `docker image prune` — удалить неиспользуемые образы |

Не помогло — пришлите преподавателю текст ошибки целиком и вывод `docker compose ps`.

<details>
<summary>Запуск dbt без Docker (необязательно)</summary>

Базы всё равно запускайте через Docker (шаг 5). dbt можно поставить локально, если у вас Python **3.10–3.13**. На 3.14 dbt пока не работает.

```bash
python3.12 -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
dbt debug
```

Файл `profiles.yml` dbt возьмёт из папки проекта; подключение по умолчанию — Greenplum на `localhost:5440`.
</details>
