# Сессия 12 · Итоговое задание
dur: ~3 ч

## 12.1 Задание: сервисы отчёта и бэкапа для CoffeeShop | short: Итоговое ТЗ | est: ~3 ч
### intro
**Слова шага:** *техническое задание (ТЗ)*, *приёмка*, *самопроверка*, *профиль Compose*, *разовая задача (job)*.

:::tip Если совсем просто
До сих пор ты шла по маршруту, который я показывала. Теперь **маршрута нет**: есть заказ от хозяйки кофейни и список требований. Что делать, ты знаешь — ты прошла 11 сессий. Открой шпаргалку, свои файлы, `--help` и справочные страницы лабы — и сделай сама.
:::

Это сессия без новой теории: ты сама дорабатываешь CoffeeShop по описанию, используя всё пройденное. Готового решения здесь нет, и так задумано: смотри свои файлы из сессий 4–11, справочные страницы лабы и документацию Docker.

**Задача.** Хозяйка кофейни хочет два новых режима работы: **ежедневный отчёт по заказам** и **резервную копию базы**. Нужно добавить в проект два сервиса, `report` и `backup`, **не меняя код API и сайта**. Основной стек должен продолжить работать как раньше.

```svg
<svg viewBox="0 0 640 285" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Целевая архитектура итогового задания" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m1-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m1-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><rect x="10" y="20" width="620" height="150" rx="8" fill="currentColor" fill-opacity="0.02" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="320" y="14" text-anchor="middle" font-size="12" font-weight="700" fill="currentColor" fill-opacity="1">основной стек (уже работает)</text><rect x="25" y="60" width="100" height="50" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="75.0" y="81.0" text-anchor="middle" font-size="12" fill="currentColor">web</text><text x="75.0" y="99.0" text-anchor="middle" font-size="12" fill="currentColor">nginx</text><rect x="170" y="60" width="100" height="50" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="220.0" y="81.0" text-anchor="middle" font-size="12" fill="currentColor">api</text><text x="220.0" y="99.0" text-anchor="middle" font-size="12" fill="currentColor">Node</text><rect x="330" y="60" width="100" height="50" rx="8" fill="currentColor" fill-opacity="0.16" stroke="currentColor" stroke-width="1.5"/><text x="380.0" y="81.0" text-anchor="middle" font-size="12" fill="currentColor">db</text><text x="380.0" y="99.0" text-anchor="middle" font-size="12" fill="currentColor">PostgreSQL</text><rect x="500" y="60" width="110" height="50" rx="8" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-width="1.5"/><text x="555.0" y="81.0" text-anchor="middle" font-size="12" fill="currentColor">adminer</text><text x="555.0" y="99.0" text-anchor="middle" font-size="12" fill="currentColor">(dev)</text><line x1="125" y1="85" x2="170" y2="85" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)" marker-start="url(#m1-s)"/><line x1="270" y1="85" x2="330" y2="85" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)" marker-start="url(#m1-s)"/><line x1="500" y1="85" x2="430" y2="85" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)"/><text x="320" y="150" text-anchor="middle" font-size="12" font-weight="700" fill="currentColor" fill-opacity="1">нужно добавить два новых сервиса ↓</text><rect x="60" y="195" width="200" height="56" rx="8" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="160.0" y="219.0" text-anchor="middle" font-size="12" fill="currentColor">report (profile reports)</text><text x="160.0" y="237.0" text-anchor="middle" font-size="12" fill="currentColor">CSV → том reports</text><rect x="380" y="195" width="200" height="56" rx="8" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="480.0" y="219.0" text-anchor="middle" font-size="12" fill="currentColor">backup (profile ops)</text><text x="480.0" y="237.0" text-anchor="middle" font-size="12" fill="currentColor">pg_dump → ./backups</text><line x1="160" y1="195" x2="360" y2="112" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)"/><line x1="480" y1="195" x2="400" y2="112" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)"/><text x="320" y="275" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">оба запускаются по требованию, без изменений в коде API и сайта</text></svg>
```

**Что нужно сделать.** Работай в копии проекта: `cp -r ~/docker-lab/starter ~/docker-lab/final && cd ~/docker-lab/final` (и всегда запускай Compose с отдельным именем проекта: `docker compose -p final …`, чтобы не задеть данные основного стека).

**A. Сервис `report` (отчёт по заказам)**

1. Папка `report/` с `Dockerfile` и скриптом `report.sh`. Образ собирается на `alpine:3.22` (версия закреплена), ставит клиент PostgreSQL и работает **не от root** (пользователь с UID 1000). В Alpine 3.22 самый свежий клиент — пакет `postgresql17-client`: для простого SQL-запроса клиент версии 17 к серверу 18 подходит (а вот для `pg_dump` клиент должен быть **не старше сервера** — поэтому бэкап в части B делает образ `postgres:18`).
2. Подключение к базе — через переменные окружения `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` (как у API). Пароль не хранится в образе и не печатается в логах.
3. Скрипт выполняет SQL и записывает **CSV-файл** `/reports/orders-<ГГГГ-ММ-ДД>.csv` с колонками `name,orders,revenue` (название позиции, число заказов, выручка = число заказов × цена), отсортированный по выручке. В `stdout` печатается краткая сводка: всего заказов и общая выручка.
4. Каталог `/reports` — **именованный том** `reports`; корневая файловая система контейнера **только для чтения**; все лишние capabilities убраны.
5. Сервис описан с профилем `reports`: его **нет** в обычном `docker compose up`, а запускается он командой `docker compose --profile reports run --rm report`. Перед стартом он дожидается здоровой базы.
6. Если базы нет или пароль неверный, скрипт пишет понятное сообщение в `stderr` и завершается с кодом, отличным от `0`.

**B. Сервис `backup` (резервная копия)**

1. Сервис на готовом образе `postgres:18` (собирать свой не нужно) с профилем `ops`; запускается командой `docker compose --profile ops run --rm backup`.
2. Скрипт `backup/backup.sh` (подключается в контейнер **только для чтения**) делает `pg_dump` и сохраняет файл `coffee-<ГГГГММДД-ЧЧММСС>.sql` в папку `./backups` на хосте (bind mount).
3. Скрипт хранит **не больше 7 последних** копий: более старые удаляет.
4. В `README.md` проекта описана **процедура восстановления**: как из файла копии поднять новую пустую базу в отдельном томе и убедиться, что в таблице `menu` три позиции.

**C. Compose и окружения**

1. Оба сервиса описаны в основном `compose.yaml` и работают в режимах dev и prod (`compose.override.yaml`, `compose.prod.yaml`).
2. У новых сервисов заданы лимит памяти, ограничение логов и (где применимо) `read_only`/`cap_drop`/`no-new-privileges` по образцу prod-накладки.
3. `compose.release.yaml` дополнен сервисом `report` в виде `image:` (из registry, по `REGISTRY` и `VERSION`); `backup` остаётся на `postgres:18`.
4. Нигде нет тега `latest`, секреты — только в `.env` (в `.gitignore`), в репозитории — `.env.example`.

**D. CI**

1. Workflow `.github/workflows/publish.yml` дополнен: образ `report` собирается и публикуется вместе с `api` и `web` (через `matrix`). Файл проходит `actionlint` без замечаний. (Запуск на GitHub выполняется самостоятельно, если хочешь, — как в шаге 10.6.)

**E. Проверки**

1. `release-check.sh` дополнен пунктами: образ `report` работает не от root; сканер не находит HIGH/CRITICAL в `report`; запуск `report` создаёт CSV; запуск `backup` создаёт файл копии.
2. `smoke.sh` по-прежнему проходит, `release-check.sh` печатает «РЕЛИЗ МОЖНО ВЫПУСКАТЬ».

**F. Документация**

1. `README.md` дополнен: как запустить отчёт, как сделать бэкап, как восстановиться, где лежат файлы.

**Чего не требуется:** красивого оформления отчёта, графиков, отправки отчёта по почте, расписания (cron), веб-интерфейса для бэкапов. Главное — чтобы всё запускалось одной командой, было безопасным, воспроизводимым и проверялось скриптом.

**Порядок работы (подсказка, не решение):** сначала вручную, одной командой `docker compose exec db psql …`, получи нужные цифры SQL-запросом; затем оформи это как скрипт; затем упакуй в образ и сервис Compose с профилем; потом ограничения безопасности; потом бэкап; потом CI и проверки; в конце README. После **каждого** шага запускай `docker compose -p final config -q` и смотри `docker compose -p final ps -a` и `logs`.

### why
Прочитать готовый шаг и выполнить его — один навык, а собрать решение по описанию — другой. Здесь вместе работают образы, Dockerfile, Compose, переменные, сети, тома, права, безопасность, registry и CI. Если на каком-то пункте ты застряла — ты нашла тему, к которой стоит вернуться: номера шагов подскажут, где её искать.

### deep Куда смотреть, если застряла (не решение, только адреса)
- **Образ и пользователь:** шаги 4.2, 4.6, 5.4 (`USER`, `adduser`, `read_only`).
- **Переменные и ожидание базы:** шаги 8.4, 8.5 (`environment`, `depends_on`, `healthcheck`).
- **Профили и разовые задачи:** шаги 9.1, 8.3 (`profiles`, `run --rm`).
- **Тома и bind mount, права на файлы:** шаги 7.2, 7.3, 7.5.
- **`pg_dump`, восстановление:** шаг 7.6.
- **Ограничения и логи:** шаги 5.4, 9.4, 11.2.
- **Workflow и `matrix`:** шаг 10.6; **релизный compose:** шаг 11.4; **проверки:** шаг 11.3.
- **Диагностика:** `docker compose -p final ps -a`, `logs`, `inspect`; справочник ошибок в конце лабы.

### quiz
Проверь себя: выполнено ли задание?
- `docker compose -p final --profile reports run --rm report` создаёт `/reports/orders-<дата>.csv` и печатает сводку; в CSV есть колонки `name,orders,revenue`, выручка посчитана верно (сверь с `psql` вручную).
- Образ `report` собран из Dockerfile на закреплённой версии Alpine, процесс работает не от root, корневая ФС только для чтения, том `reports` сохраняет файл после удаления контейнера.
- При неверном пароле `report` завершается ненулевым кодом и пишет понятное сообщение в `stderr`.
- `docker compose -p final --profile ops run --rm backup` создаёт файл `./backups/coffee-….sql`; после десяти запусков в папке остаётся **не больше 7** файлов.
- Восстановление по README действительно работает: в новой пустой базе три позиции меню.
- Обычный `docker compose up -d` (без профилей) по-прежнему поднимает только `db`, `api`, `web` (+ `adminer` в dev); `report` и `backup` не стартуют.
- `compose.release.yaml` содержит `report` с `image:`; нигде нет `latest`; `.env` не в репозитории.
- Workflow публикует три образа через `matrix` и проходит `actionlint`.
- `./release-check.sh` проходит все пункты (включая новые), `./smoke.sh` проходит.
- Ты можешь объяснить вслух, зачем каждому из двух сервисов нужен именно этот профиль, том и набор ограничений.

### outro
:::tip Приёмка лабы
Если все пункты выше выполнены, ты умеешь довести задачу от описания до рабочего, безопасного и проверяемого решения на Docker: от образа до Compose, registry и CI. Отправлять решение никуда не нужно; ответа в методичке нет.
:::
