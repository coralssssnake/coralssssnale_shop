# Как запустить проект семинара: Git и Docker

Эта инструкция — от чистого компьютера до команды `All checks passed!`. Если у вас уже работают Git и Docker Desktop, переходите сразу к [шагу 3](#шаг-3-освободить-ресурсы-от-прошлых-стендов).

**Сделайте шаги 1–6 до семинара.** Сборка образа скачивает dbt из интернета, а на паре 25 человек одновременно на одном Wi-Fi будут ждать долго.

## Что получится

```text
ваш компьютер
├── Git     — скачивает проект с GitHub и сохраняет вашу работу
└── Docker  — запускает две программы в контейнерах:
    ├── postgres — база интернет-магазина (порт 5436)
    └── dbt      — собирает витрины в этой базе
```

Устанавливать Python, PostgreSQL и dbt на компьютер **не нужно**: всё работает внутри Docker.

## Что понадобится

| Что | Зачем | Проверка |
|---|---|---|
| Git | Скачать проект и сдать домашку | `git --version` |
| Docker Desktop | Запустить базу и dbt | `docker compose version` |
| DBeaver | Смотреть таблицы в базе (уже есть с прошлых практик) | — |
| ~3 ГБ свободного места и интернет | Скачать образы при первом запуске | — |

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

Какой у вас процессор, видно в меню  → «Об этом Mac».

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

Стенд практики 3 (Greenplum + ClickHouse) занимает много памяти. Если он ещё работает, остановите его. Данные при этом сохранятся:

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

## Шаг 5. Запустить базу

```bash
docker compose up -d postgres
docker compose ps
```

Первый запуск скачивает образ PostgreSQL и загружает данные магазина, это займёт до минуты. Повторяйте `docker compose ps`, пока в колонке `STATUS` не появится `(healthy)`:

```text
NAME                  ...   STATUS                    PORTS
dbt_shop-postgres-1   ...   Up 20 seconds (healthy)   0.0.0.0:5436->5432/tcp
```

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

Создайте новое подключение: **База данных → Новое соединение → PostgreSQL**.

| Параметр | Значение |
|---|---|
| Хост | `localhost` |
| Порт | **`5436`** — не 5435 и не 5438, это порты прошлых практик |
| База данных | `shop` |
| Пользователь | `student` |
| Пароль | `studentpass` |

Нажмите **Тест соединения**. В схеме `public` должны быть таблицы `customers`, `orders`, `payments` и другие. Схемы `analytics_*` появятся после первого запуска dbt.

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
| Начать работу | Запустить Docker Desktop, перейти в папку `store`, выполнить `docker compose up -d postgres` |
| Закончить работу (данные сохранятся) | `docker compose down` |
| Начать с чистой базы (**удалит** все таблицы, которые построил dbt) | `docker compose down -v`, затем `docker compose up -d postgres` |

Ваш код хранится в файлах в папке `store` и в Git, а не в базе. Поэтому `down -v` код не удаляет: следующий `dbt build` заново построит все витрины.

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
| `port is already allocated` / `address already in use` | Порт 5436 занят другой программой | `PG_PORT=5546 docker compose up -d postgres` (в PowerShell: `$env:PG_PORT=5546; docker compose up -d postgres`) и порт `5546` в DBeaver. Для dbt менять ничего не нужно |
| `Bind for 0.0.0.0:8080 failed` при `docs serve` | Порт 8080 занят | Добавить `DOCS_PORT=8081` перед командой `docker compose run … docs serve …` (в PowerShell: `$env:DOCS_PORT=8081;` перед командой) и открыть http://localhost:8081. Саму команду менять не нужно |
| Сборка `docker compose build dbt` падает на `pip install` | Нет доступа к интернету или к PyPI | Проверить интернет, отключить VPN или прокси, повторить |
| `permission denied ... docker.sock` (Linux) | Пользователь не в группе `docker` | `sudo usermod -aG docker $USER` и перезайти |
| `WSL 2 installation is incomplete` (Windows) | Не установлен WSL | `wsl --install` от администратора, перезагрузка |
| `fatal: destination path 'store' already exists` | Проект уже скачан | Перейти в существующую папку: `cd store` |
| DBeaver: `password authentication failed` или нет таблиц | Подключение идёт к базе прошлой практики | Проверить порт: **5436** |
| `Could not connect to the database` в `dbt debug` | База ещё стартует | Подождать `(healthy)` в `docker compose ps` и повторить |
| dbt: `column "todo" does not exist` | В модели остались незаполненные `TODO` | Это нормально: заполните задание |
| Мало места на диске | Старые образы и тома | `docker system df` — посмотреть, `docker image prune` — удалить неиспользуемые образы |

Не помогло — пришлите преподавателю текст ошибки целиком и вывод `docker compose ps`.

<details>
<summary>Запуск dbt без Docker (необязательно)</summary>

Базу всё равно запускайте через Docker (шаг 5). dbt можно поставить локально, если у вас Python **3.10–3.13**. На 3.14 dbt пока не работает.

```bash
python3.12 -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
dbt debug
```

Файл `profiles.yml` dbt возьмёт из папки проекта; подключение по умолчанию — `localhost:5436`.
</details>
