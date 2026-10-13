# Сессия 9 · Docker Compose, часть 2
dur: ~4 ч

## 9.1 profiles, несколько файлов, override | short: Профили и override | est: ~40 мин
### intro
**Слова шага:** *профиль (`profiles`)*, *`-f`*, *`compose.override.yaml`*, *слияние файлов*, *dev и prod*.

:::tip Если совсем просто
В кофейне есть **базовое меню**, а в праздники — **дополнения**. Compose умеет так же: основной файл — всегда, а дополнительные «накладки» (для разработки, для боевого сервера) **накладываются сверху** и меняют только то, что нужно. А «профили» — это переключатели: «этот сервис запускать только по просьбе».
:::

Прежде чем начать, остановим стек из прошлой сессии, чтобы он не занимал порты:

```bash run
cd ~/docker-lab/coffeeshop
docker compose down
```

### result
```out auto
```

**Профили.** Не всё нужно запускать всегда: Adminer, отладочные утилиты, одноразовые задачи нужны «по требованию». Сервису можно присвоить профиль: он **не запускается**, пока профиль явно не включён. Покажем на маленьком проекте: база и два сервиса — обычный и «инструментальный»:

```bash run
mkdir -p ~/docker-lab/s09/prof && cd ~/docker-lab/s09/prof
cat > compose.yaml <<'EOF'
services:
  app:
    image: nginx:1.30-alpine
  adminer:
    image: adminer:5
    profiles: [tools]
  seed:
    image: alpine:3.22
    profiles: [setup]
    command: echo "разовая задача"
EOF
echo "--- без профилей:"
docker compose config --services
echo "--- с профилем tools:"
docker compose --profile tools config --services
echo "--- с двумя профилями:"
docker compose --profile tools --profile setup config --services
```

```out auto
```

Без профилей запускается только `app`; `--profile tools` добавляет `adminer`; можно включать несколько. Для одноразовых задач удобен `docker compose run --rm seed` — он запускает сервис с профилем **без** включения профиля (команда `run` указывает сервис явно).

**Несколько файлов и слияние.** Один основной файл и «накладки». Флаг `-f` можно повторять: файлы читаются по порядку, и каждый следующий **дополняет и перезаписывает** предыдущий. Особый случай: если рядом с `compose.yaml` лежит **`compose.override.yaml`**, Compose подмешивает его **автоматически** — так принято хранить настройки для разработки:

```bash run
cd ~/docker-lab/s09/prof
cat > compose.override.yaml <<'EOF'
services:
  app:
    ports:
      - "8093:80"
    environment:
      MODE: dev
EOF
echo "--- docker compose config (override подмешан автоматически):"
docker compose config | grep -E 'MODE|published|target'
echo "--- только основной файл (-f отключает автоматический override):"
docker compose -f compose.yaml config | grep -E 'MODE|published|target' || echo "(ни портов, ни MODE: этого нет в основном файле)"
```

```out auto
```

В первом случае в итоговой конфигурации есть и порт 8093, и `MODE: dev` — из `compose.override.yaml`; во втором (`-f compose.yaml` явно) override не читается. Правила слияния: простые значения (`image`, `command`) **заменяются**; словари (`environment`) **объединяются**; списки (`ports`, `volumes`) **дополняются**. Именно так делают раскладку: **основной файл — «боевой»** (без лишних портов, с ограничениями), **override — для разработки** (порты наружу, bind mount, отладка), а для сервера — ещё один файл `compose.prod.yaml`, подключаемый явно (шаг 9.6).

### why
Один набор файлов на все окружения вместо копий `compose.dev.yaml`, `compose.test.yaml`, `compose.prod.yaml` с повторяющимся кодом. Основной файл описывает **что за приложение**, а накладки — **как его запускать здесь**. Ошибок меньше: общая часть записана ровно один раз.

### deep Команда по частям
`docker compose --profile tools config --services`: `--profile tools` — включить профиль `tools`; `config --services` — вывести только имена сервисов, которые будут запущены. Профиль можно включить и переменной окружения: `COMPOSE_PROFILES=tools,setup docker compose up -d`.

### deep Как ещё можно
- **Явный набор файлов:** `docker compose -f compose.yaml -f compose.prod.yaml up -d`.
- **Список файлов в переменной:** `COMPOSE_FILE=compose.yaml:compose.prod.yaml` (разделитель `:`).
- **Сервис без профиля, от которого зависит сервис с профилем** — запустится вместе; наоборот — нет: сервис без профиля не может зависеть от сервиса с профилем.

### deep Если не получилось
- **Сервис с профилем не запускается** — профиль не включён: добавь `--profile имя`.
- **Override «не работает»** — файл назван не `compose.override.yaml` или запуск идёт с явными `-f` (тогда он не подмешивается).
- **Список (`ports`) задвоился** — списки при слиянии дополняются; если нужно заменить, используй тег `!override` (в новых версиях Compose) или убери ключ из основного файла.

### quiz
- Что делает `profiles: [tools]` у сервиса?
- Какие значения при слиянии заменяются, а какие объединяются?
- Когда `compose.override.yaml` читается автоматически, а когда нет?

### links
- https://docs.docker.com/compose/how-tos/profiles/ | профили Compose | Using profiles
- https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/ | слияние файлов | Merge Compose files

## 9.2 Переиспользование: extends, include, якоря, x- | short: Не повторяться | est: ~35 мин
### intro
**Слова шага:** *`extends`*, *`include`*, *якорь `&`/`*`*, *расширение `x-`*, *DRY*.

:::tip Если совсем просто
Если одинаковую запись ты переписываешь в пяти местах — один раз ошибёшься и забудешь обновить остальные. Лучше **написать один раз и ссылаться**. Для этого в Compose есть несколько способов: «шаблон-заготовка» (`x-`), «взять за образец другого» (`extends`) и «подключить кусок чужого проекта» (`include`).
:::

Четыре способа не копировать одно и то же. Все видны на одном маленьком проекте:

```bash run
mkdir -p ~/docker-lab/s09/reuse/common && cd ~/docker-lab/s09/reuse
cat > common/base.yaml <<'EOF'
services:
  base-app:
    image: alpine:3.22
    restart: unless-stopped
    environment:
      TZ: Europe/Moscow
    command: sleep 300
EOF
cat > tools.yaml <<'EOF'
services:
  tool:
    image: alpine:3.22
    command: echo "я из подключённого файла"
EOF
cat > compose.yaml <<'EOF'
include:
  - tools.yaml

x-logging: &logging
  driver: json-file
  options:
    max-size: "5m"
    max-file: "2"

services:
  one:
    extends:
      file: common/base.yaml
      service: base-app
    logging: *logging
  two:
    extends:
      file: common/base.yaml
      service: base-app
    command: sleep 600
    logging: *logging
EOF
docker compose config --services | sort
docker compose config | grep -E '^  (one|two|tool):|restart:|max-size:|^      - (sleep|echo|"[0-9]+")'
```

### result
```out auto
```

Разбор. **`extends`** — сервис «наследует» настройки другого сервиса из другого файла (`file` + `service`) и может переопределить своё: `one` взял всё из `base-app`, а `two` — всё, **кроме `command`**. **`include`** — подключает **целый другой файл** со всеми его сервисами (`tool` появился в списке без единой строки описания в основном файле). **`x-logging` + якорь `&logging` / ссылка `*logging`** — заготовка внутри самого файла: описана один раз, использована дважды (ключи на `x-` Compose игнорирует). Итог: настройки логов написаны один раз, а действуют на оба сервиса.

Когда что использовать: **якоря и `x-`** — для повторов **в одном файле**; **`extends`** — для общей основы **нескольких сервисов** (в том числе из разных файлов); **`include`** — чтобы собрать большой проект из **готовых кусков** (например, общая база данных для нескольких приложений).

### why
Повторы в конфигурации — главный источник расхождений («здесь поправила, там забыла»). Три-четыре строки заготовки в начале файла избавляют от этого. Но не усердствуй: если файл стал похож на головоломку из ссылок, лучше немного повторов, чем нечитаемость.

### deep Команда по частям
`docker compose config | grep -E '…'`: выводим итоговую конфигурацию и оставляем строки с именами сервисов (`one`, `two`, `tool`), политикой перезапуска, лимитом лога и командами (`command` в итоговом виде — список слов). `sort` в предыдущей команде упорядочивает список сервисов по алфавиту, чтобы вывод был стабильным.

### deep Как ещё можно
- **Слияние словарей через якорь:** `<<: *logging` вставляет ключи заготовки внутрь блока, к которому можно дописать свои (шаг 8.1).
- **`include` с переменными проекта:** `include: - path: ../shared/db.yaml`, `env_file: db.env`.
- **Не путай `extends` с `depends_on`:** `extends` наследует **настройки**, а не связи запуска.

### deep Если не получилось
- **`extends … service not found`** — имя сервиса в `service:` не совпадает с именем в файле-источнике.
- **`include`-ed path not found`** — путь относительный от файла, который его подключает.
- **Ключи `x-…` попали в вывод `docker compose config`** — нормально: Compose сохраняет расширения, но не считает их сервисами.

### quiz
- Чем `extends` отличается от `include`?
- Что такое ключи `x-…` и зачем они нужны?
- Когда стоит оставить повтор, а не использовать якорь?

### links
- https://docs.docker.com/compose/how-tos/multiple-compose-files/extends/ | extends | Extend
- https://docs.docker.com/compose/how-tos/multiple-compose-files/include/ | include | Include

## 9.3 compose watch: разработка с автообновлением | short: compose watch | est: ~30 мин
### intro
**Слова шага:** *`develop.watch`*, *`docker compose watch`*, *действия `sync` и `rebuild`*, *`bind mount` против `watch`*.

:::tip Если совсем просто
Ты правишь файл — а помощник **сам замечает** и переносит изменение в контейнер. Не надо ничего перезапускать и пересобирать вручную. Как автоматический переводчик: ты пишешь по-русски, у собеседника сразу появляется перевод.
:::

В шаге 7.3 мы монтировали папку (bind mount), чтобы правки были видны сразу. У этого есть минусы (права, скорость на Mac). **`docker compose watch`** — альтернатива: Compose сам следит за файлами и по правилам отправляет изменения в контейнер. В `compose.yaml` описывается секция `develop.watch`. Основные действия:

- **`sync`** — скопировать изменённые файлы в контейнер (для статики и интерпретируемого кода); `initial_sync: true` — ещё и сразу при запуске привести контейнер в соответствие с папкой;
- **`rebuild`** — пересобрать образ и пересоздать контейнер (при смене зависимостей);
- **`sync+restart`** — скопировать и перезапустить процесс.

Опробуем на статическом сайте: правим `site/index.html`, и страница меняется без перезапуска. `watch` работает в переднем плане, поэтому запустим его в фоне оболочки (`&`), поменяем файл и остановим:

```bash run
mkdir -p ~/docker-lab/s09/watch/site && cd ~/docker-lab/s09/watch
echo '<h1>версия 1</h1>' > site/index.html
cat > compose.yaml <<'EOF'
services:
  site:
    image: nginx:1.30-alpine
    ports:
      - "8092:80"
    develop:
      watch:
        - action: sync
          path: ./site
          target: /usr/share/nginx/html
          initial_sync: true
EOF
docker compose up -d > /dev/null 2>&1
docker compose watch > watch.log 2>&1 &
WPID=$!
sleep 4
curl -s http://localhost:8092
echo '<h1>версия 2</h1>' > site/index.html
sleep 4
curl -s http://localhost:8092
kill $WPID
sleep 1
cat watch.log
docker compose down > /dev/null 2>&1
```

### result
```out auto
```

Первый запрос — «версия 1», затем мы изменили файл на хосте, и через секунду второй запрос показал «версия 2». В журнале `watch` — строка `Syncing service "site" after 1 changes were detected`: Compose заметил изменение и отправил файл в контейнер. Заметь: образ не пересобирали и контейнер не перезапускали. На своём Mac ты запускаешь так: `docker compose up -d` и в **отдельном окне терминала** `docker compose watch` (или сразу `docker compose up --watch`), правишь файлы в редакторе — и всё обновляется.

Для приложения с зависимостями правила пишут так: код — `sync+restart`, а файл зависимостей — `rebuild` (так, чтобы при смене `package.json` образ собирался заново):

```yaml
develop:
  watch:
    - action: sync+restart
      path: ./api/server.js
      target: /app/server.js
    - action: rebuild
      path: ./api/package.json
```

(Это пример для чтения; запускать его мы не будем.)

### why
`watch` — быстрый цикл разработки: правка → результат через секунду, но **образ остаётся честным** (он не завязан на содержимое папки на хосте, как при bind mount). В продакшн-режиме файлы лежат внутри образа; `watch` — инструмент только для разработки.

### deep Команда по частям
`docker compose watch > watch.log 2>&1 &`: `watch` — следить за изменениями; `> watch.log 2>&1` — записывать вывод и ошибки в файл; `&` — запустить в фоне оболочки; `WPID=$!` запоминает номер процесса, чтобы потом остановить его `kill $WPID`.

### deep Как ещё можно
- **Игнорировать файлы:** в правило добавляют `ignore: [node_modules/, "*.log"]`.
- **`up --watch`:** одна команда вместо двух: запускает контейнеры и следит за файлами.
- **Bind mount вместо `watch`:** проще (шаг 7.3), но на Mac медленнее для больших папок и может давать проблемы с правами.

### deep Если не получилось
- **Файл меняется, но страница старая** — путь `path` не тот, который редактируешь, или `target` не совпадает с папкой, откуда читает сервер.
- **`watch` ничего не пишет** — в файле нет секции `develop.watch` у нужных сервисов.
- **`watch` выходит сразу** — сервис не запущен: сначала `docker compose up -d`.

### quiz
- Чем `docker compose watch` отличается от bind mount?
- В каких случаях нужен `rebuild`, а в каких хватит `sync`?
- Для какого окружения предназначен `watch` и почему не для продакшна?

### links
- https://docs.docker.com/compose/how-tos/file-watch/ | compose watch | Use Compose Watch

## 9.4 restart, лимиты, логи, остановка | short: restart, лимиты, логи | est: ~45 мин
### intro
**Слова шага:** *`restart`*, *политики перезапуска*, *`mem_limit`*, *`cpus`*, *OOM*, *`logging`*, *`stop_grace_period`*, *`init`*.

:::tip Если совсем просто
Работник может упасть, зависнуть или съесть все продукты на кухне. У Compose есть четыре «правила внутреннего распорядка»: **перезапускать упавшего**, **выдать каждому лимит продуктов** (память), **ограничить дневник** (чтобы логи не заполнили диск) и **дать время собраться** при остановке.
:::

Четыре группы настроек, без которых сервис нельзя выпускать в продакшн.

**1. `restart`** — что делать, когда процесс завершился. Политики: `no` (по умолчанию — не перезапускать), `on-failure` (только если код выхода ненулевой; можно `on-failure:3` — не более трёх раз), `always` (всегда), `unless-stopped` (всегда, кроме случая, когда сервис остановлен вручную). Покажем: сервис падает с ошибкой, а политика его поднимает:

```bash run
mkdir -p ~/docker-lab/s09/restart && cd ~/docker-lab/s09/restart
cat > compose.yaml <<'EOF'
services:
  flaky:
    image: alpine:3.22
    restart: on-failure:3
    command: sh -c 'echo "стартую и падаю"; exit 1'
EOF
docker compose up -d > /dev/null 2>&1
sleep 6
docker inspect --format 'перезапусков: {{.RestartCount}}, состояние: {{.State.Status}}, код: {{.State.ExitCode}}' restart-flaky-1
docker compose down > /dev/null 2>&1
```

### result
```out auto
```

Compose перезапускал упавший сервис **три раза** (`on-failure:3`) и остановился: дальше падать бесконечно нет смысла — нужно смотреть `logs`. Для постоянных сервисов (`api`, `web`, `db`) ставят `unless-stopped`: после сбоя или перезагрузки сервера они поднимутся сами.

**2. Лимиты ресурсов.** `mem_limit` и `cpus` ограничивают сервис (cgroups из шага 1.2). Если процесс превысит память — ядро убьёт его, и признак — код `137` и флаг `OOMKilled`. Покажем на «прожорливом» сервисе (`tail /dev/zero` бесконечно читает нули в память):

```bash run
mkdir -p ~/docker-lab/s09/limits && cd ~/docker-lab/s09/limits
cat > compose.yaml <<'EOF'
services:
  hog:
    image: alpine:3.22
    mem_limit: 32m
    command: sh -c 'tail /dev/zero'
EOF
docker compose up -d > /dev/null 2>&1
sleep 3
docker compose ps -a --format 'table {{.Service}}\t{{.Status}}'
docker inspect --format 'OOMKilled={{.State.OOMKilled}} код={{.State.ExitCode}}' limits-hog-1
docker compose down > /dev/null 2>&1
```

```out auto
```

`Exited (137)` и `OOMKilled=true`: сервис превысил 32 МБ, и его убило ядро — это **ограничение сработало**. Без лимита такой процесс съел бы всю память VM и затормозил бы все остальные контейнеры. Поэтому в продакшне у каждого сервиса стоит разумный `mem_limit` (и, при необходимости, `cpus`, `pids_limit`).

**3. Логи.** По умолчанию логи контейнера лежат в JSON-файле и **растут бесконечно**. Ограничим размер и число файлов:

```yaml
logging:
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"
```

Тогда журнал хранит не больше `3 × 10 МБ` и перезаписывает старое (мы использовали такую заготовку в шаге 9.2).

**4. Остановка.** `stop_grace_period` — сколько ждать после SIGTERM перед SIGKILL (по умолчанию 10 секунд, шаг 2.6). Для быстрой остановки у простого сервиса можно уменьшить; для базы, которой нужно время на запись, — увеличить. А `init: true` запускает перед процессом крошечный «менеджер процессов», который корректно передаёт сигналы и убирает процессы-«зомби» (шаг 4.6). Проверим влияние `stop_grace_period`: сервис, игнорирующий SIGTERM, останавливаем с короткой «грейс-паузой» в 2 секунды:

```bash run
mkdir -p ~/docker-lab/s09/grace && cd ~/docker-lab/s09/grace
cat > compose.yaml <<'EOF'
services:
  slow:
    image: alpine:3.22
    command: sleep 1000
    stop_grace_period: 2s
EOF
docker compose up -d > /dev/null 2>&1
time docker compose stop slow > /dev/null 2>&1
docker compose down > /dev/null 2>&1
```

```out auto
```

Остановка заняла около 2 секунд вместо 10 (`real 0m2…`): Compose подождал только `stop_grace_period`, затем убил процесс.

### why
Эти четыре настройки отличают «работает у меня» от «выдержит боевую нагрузку»: упавший сервис поднимется, одно приложение не съест всю память, логи не забьют диск, а остановка не растянется на минуты. В шаге 9.6 они попадут в наш `compose.prod.yaml`.

### deep Команда по частям
`docker inspect --format 'перезапусков: {{.RestartCount}}, …' restart-flaky-1`: `RestartCount` — сколько раз Docker перезапускал контейнер; `.State.Status` и `.State.ExitCode` — состояние и код. Имя контейнера `restart-flaky-1` = `проект-сервис-номер` (шаг 8.2). `time … > /dev/null 2>&1` замеряет команду, скрывая её вывод.

### deep Как ещё можно
- **Лимиты через `deploy`:** `deploy.resources.limits.memory: 256M` и `cpus: "0.5"` — то же, но форма, общая с Swarm/Kubernetes-описаниями; для Compose работают обе.
- **Проверка лимитов «вживую»:** `docker stats --no-stream`.
- **`restart: always` против `unless-stopped`:** `always` перезапустит даже вручную остановленный сервис после перезагрузки Docker; `unless-stopped` — нет.
- **Сменить драйвер логов:** `local`, `syslog`, `fluentd` и др. (в продакшне логи отправляют в централизованную систему).

### deep Если не получилось
- **Сервис в бесконечном `Restarting`** — политика `always`/`unless-stopped` поднимает падающий процесс снова и снова: смотри `docker compose logs`, чини причину, не мани политику.
- **`OOMKilled=true`, а приложение «в норме»** — лимит слишком мал; подними `mem_limit` или найди утечку.
- **`stop_grace_period` не работает** — сервис всё равно ждёт 10 секунд: проверь, что ключ записан внутри сервиса, а не на верхнем уровне.

### quiz
- Чем `on-failure:3` отличается от `unless-stopped`?
- Что означают `Exited (137)` и `OOMKilled=true` в связке с `mem_limit`?
- Зачем ограничивать размер логов и что будет без этого?

### links
- https://docs.docker.com/reference/compose-file/services/#restart | restart | restart
- https://docs.docker.com/engine/containers/resource_constraints/ | ограничение ресурсов | Resource constraints

## 9.5 Масштабирование: --scale и его ограничения | short: Масштабирование | est: ~30 мин
### intro
**Слова шага:** *реплика*, *`--scale`*, *DNS-имя сервиса*, *конфликт портов*, *балансировка*.

:::tip Если совсем просто
Очередь выросла — поставь за стойку **не одного, а троих** кассиров. Для Compose это команда «`--scale касса=3`». Но у всех кассиров один и тот же адрес на двери (порт), и дверь на трёх одинаково не повесишь — об этом ограничении ниже.
:::

Сервис можно запустить в нескольких копиях (**репликах**) флагом `--scale`. Все реплики подключены к сети проекта и получают одно общее имя, по которому DNS отдаёт адреса **всех** копий:

```bash run
mkdir -p ~/docker-lab/s09/scale && cd ~/docker-lab/s09/scale
cat > compose.yaml <<'EOF'
services:
  app:
    image: nginx:1.30-alpine
EOF
docker compose up -d --scale app=3 > /dev/null 2>&1
docker compose ps --format 'table {{.Name}}\t{{.Service}}\t{{.Status}}'
docker run --rm --network scale_default alpine:3.22 nslookup app
```

### result
```out auto
```

Три контейнера `scale-app-1`, `-2`, `-3`, и DNS-имя `app` разрешается сразу в **три адреса** — другие контейнеры сети, обращаясь к `app`, получат ответ от одной из реплик (простейшая балансировка по кругу, *DNS round robin*). Теперь ограничение. Если у сервиса стоит **фиксированный порт хоста**, копии не поместятся: порт может слушать только один процесс.

```bash run
cd ~/docker-lab/s09/scale
docker compose down > /dev/null 2>&1
cat > compose.yaml <<'EOF'
services:
  app:
    image: nginx:1.30-alpine
    ports:
      - "8094:80"
EOF
docker compose up -d --scale app=2 2>&1 | grep -iE 'error|allocated|Started' | head -4
docker compose down > /dev/null 2>&1
```

```out auto
```

Первая копия заняла порт 8094, вторая получила `port is already allocated` и не запустилась. Способы обойти: **1)** не публиковать порт у масштабируемого сервиса, а поставить перед ним балансировщик (reverse proxy), который ходит по имени сервиса — этим занимаются Traefik и Caddy (отдельные лабы); **2)** опубликовать **диапазон** портов хоста (`ports: ["8094-8096:80"]`) — тогда каждой копии достанется свой, но снаружи придётся знать все; **3)** для настоящего масштабирования использовать оркестратор (Kubernetes).

### why
`--scale` полезен для рабочих очередей, воркеров и демонстрации; для веб-сервисов с портом нужен балансировщик перед ними. Знание ограничения экономит время: «почему вторая копия не стартует» — это почти всегда фиксированный порт хоста.

### deep Команда по частям
`docker compose up -d --scale app=3`: запустить сервис `app` в трёх экземплярах (число можно менять на лету, повторив команду с другим числом). `docker run --rm --network scale_default alpine:3.22 nslookup app`: временный контейнер в сети проекта (`<проект>_default`), чтобы спросить DNS об имени `app`.

### deep Как ещё можно
- **Число реплик в файле:** `deploy.replicas: 3` (то же, что `--scale`).
- **Балансировщик:** nginx или Traefik с `proxy_pass`/`service`, где адрес — имя сервиса (из шага 6.6 мы знаем, как nginx разрешает имя).
- **Проверить, кто ответил:** сделай так, чтобы каждая реплика отдавала своё имя хоста, и вызывай её несколько раз подряд.

### deep Если не получилось
- **`port is already allocated`** — фиксированный порт хоста у масштабируемого сервиса.
- **`container_name` и `--scale`** — у масштабируемого сервиса нельзя задавать `container_name` (у копий не может быть одно имя); убери ключ.
- **Реплики не видят друг друга по имени** — у каждой реплики есть своё имя вида `проект-сервис-N`; общее имя — имя сервиса.

### quiz
- Что получат другие контейнеры, запросив DNS-имя масштабируемого сервиса?
- Почему не получится запустить две копии сервиса с `ports: ["8094:80"]`?
- Какой способ масштабирования веб-сервиса подходит вместо фиксированных портов?

### links
- https://docs.docker.com/reference/cli/docker/compose/up/ | docker compose up --scale | docker compose up

## 9.6 Мини-проект: dev и prod одним репозиторием | short: dev и prod | est: ~60 мин
### intro
**Слова шага:** *основной файл*, *`compose.override.yaml`*, *`compose.prod.yaml`*, *`profiles`*, *`.env.example`*.

:::tip Если совсем просто
У кофейни два режима: **репетиция** (разработчик: всё открыто, удобные кнопки, инструменты на столе) и **рабочий день** (всё закрыто, всё надёжно, ничего лишнего). Мы сделаем так, чтобы **одним набором файлов** и **разными командами** включался нужный режим.
:::

Соберём то, что узнали в сессии, на нашем CoffeeShop. Раскладка файлов:

- **`compose.yaml`** — основа, общая для всех режимов: сервисы, сети, том, healthcheck. Ничего лишнего наружу.
- **`compose.override.yaml`** — режим разработки (подключается автоматически): порт базы на `127.0.0.1`, Adminer, режим `development` у API.
- **`compose.prod.yaml`** — режим «боевой» (подключается явно): `restart`, лимиты, ограничение логов.
- **`.env`** — настоящие значения (не в git); **`.env.example`** — шаблон для репозитория.

Основной файл (Adminer здесь убран — он нужен только разработчику):

```bash run
cd ~/docker-lab/coffeeshop
cat > compose.yaml <<'EOF'
name: coffeeshop

services:
  db:
    image: postgres:18
    environment:
      POSTGRES_USER: ${DB_USER:-coffee}
      POSTGRES_PASSWORD: ${DB_PASSWORD:?Задай DB_PASSWORD в .env}
      POSTGRES_DB: ${DB_NAME:-coffee}
    volumes:
      - pgdata:/var/lib/postgresql
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 2s
      timeout: 3s
      retries: 15
    networks: [back]

  api:
    build: ./api
    environment:
      DB_HOST: db
      DB_USER: ${DB_USER:-coffee}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_NAME: ${DB_NAME:-coffee}
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "/nodejs/bin/node", "-e", "fetch('http://localhost:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]
      interval: 3s
      timeout: 3s
      retries: 10
    networks: [front, back]

  web:
    build: ./web
    ports:
      - "${WEB_PORT:-8080}:80"
    depends_on:
      api:
        condition: service_healthy
    networks: [front]

networks:
  front:
  back:

volumes:
  pgdata:
EOF
cat > compose.override.yaml <<'EOF'
services:
  db:
    ports:
      - "127.0.0.1:5432:5432"
  api:
    environment:
      NODE_ENV: development
  adminer:
    image: adminer:5
    ports:
      - "127.0.0.1:8081:8080"
    depends_on:
      db:
        condition: service_healthy
    networks: [back]
EOF
cat > compose.prod.yaml <<'EOF'
x-prod: &prod
  restart: unless-stopped
  logging:
    driver: json-file
    options:
      max-size: "10m"
      max-file: "3"

services:
  db:
    <<: *prod
    mem_limit: 512m
    stop_grace_period: 30s
  api:
    <<: *prod
    mem_limit: 256m
    environment:
      NODE_ENV: production
  web:
    <<: *prod
    mem_limit: 128m
EOF
cp .env .env.example
sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=change-me/' .env.example
cat .env.example
```

### result
```out auto
```

`.env.example` — шаблон без настоящего пароля: его можно класть в репозиторий. Теперь сравним два режима **не запуская ничего**, только посмотрев итоговую конфигурацию. Режим разработки (`override` подмешан автоматически):

```bash run
cd ~/docker-lab/coffeeshop
echo "--- DEV: сервисы"
docker compose config --services | sort | tr '\n' ' '; echo
echo "--- DEV: порты и режим"
docker compose config | grep -E 'published|NODE_ENV|restart|mem_limit'
echo
echo "--- PROD (-f compose.yaml -f compose.prod.yaml): сервисы"
docker compose -f compose.yaml -f compose.prod.yaml config --services | sort | tr '\n' ' '; echo
echo "--- PROD: порты, режим, перезапуск, лимиты"
docker compose -f compose.yaml -f compose.prod.yaml config | grep -E 'published|NODE_ENV|restart|mem_limit'
```

```out auto
```

В DEV — три сервиса плюс `adminer`, опубликованы порты 5432 и 8081 (только на 127.0.0.1), `NODE_ENV: development`, перезапусков и лимитов нет. В PROD — только `db`, `api`, `web`, опубликован лишь порт сайта, `NODE_ENV: production`, у всех `restart: unless-stopped` и лимиты памяти. Запустим оба режима:

```bash run
cd ~/docker-lab/coffeeshop
echo "=== DEV: docker compose up -d"
docker compose up -d --build > /dev/null 2>&1
docker compose ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
docker compose down
echo "=== PROD: docker compose -f compose.yaml -f compose.prod.yaml up -d"
docker compose -f compose.yaml -f compose.prod.yaml up -d --build > /dev/null 2>&1
docker compose -f compose.yaml -f compose.prod.yaml ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
curl -s -w '\n' http://localhost:8080/api/orders
docker inspect --format '{{.Name}}: restart={{.HostConfig.RestartPolicy.Name}} memory={{.HostConfig.Memory}}' coffeeshop-api-1 coffeeshop-web-1
```

```out auto
```

Один репозиторий — два режима, переключаемые **командой**, а не правкой файлов. В продакшн-режиме работают `db`, `api`, `web` с политиками перезапуска и лимитами; данные заказов прежние (том тот же). Следующий шаг начнём с остановки этого стека.

### why
Это рабочая схема, с которой живут реальные команды: в репозитории **один** набор Compose-файлов; на ноутбуке `docker compose up` даёт удобную среду разработки, на сервере — `-f compose.yaml -f compose.prod.yaml`. А `.env.example` позволяет новому человеку за минуту завести свой `.env`.

### deep Команда по частям
`sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=change-me/' .env.example`: `sed` — редактор потока; `-i` — править файл на месте; `s/что/на_что/` — заменить; `^DB_PASSWORD=.*` — строка, начинающаяся с `DB_PASSWORD=` и до конца. (В macOS BSD-`sed` для `-i` требует аргумента: `sed -i '' …`; в методичке команда выполнена в Linux-контейнере.) `docker compose config --services | sort | tr '\n' ' '` — список имён сервисов в одну строку.

### deep Как ещё можно
- **Переменная вместо флагов:** `export COMPOSE_FILE=compose.yaml:compose.prod.yaml` — и `docker compose up -d` везде работает в боевом режиме.
- **Разные `.env`:** `docker compose --env-file prod.env -f … up -d`.
- **Адрес базы наружу в проде:** не публикуй (у нас так и сделано); для работы с базой на сервере используй `docker compose exec db psql …` или SSH-туннель.
- **Секреты:** вместо пароля в `.env` в продакшне используют Docker secrets или менеджер секретов (за пределами этой лабы).

### deep Если не получилось
- **`Adminer` не появился в DEV** — запускаешь с явными `-f` (override не подмешан) или удалён `compose.override.yaml`.
- **В PROD порты `5432`/`8081` всё равно открыты** — в основном `compose.yaml` не должно быть этих `ports` (они живут только в override).
- **`mem_limit` не виден в `config`** — Compose выводит число в байтах (`mem_limit: "536870912"`).

### quiz
- Что лежит в основном файле, что — в `compose.override.yaml`, а что — в `compose.prod.yaml`?
- Как запустить продакшн-режим и чем он отличается от разработки в части портов?
- Зачем в репозитории `.env.example`, а настоящий `.env` в `.gitignore`?

### links
- https://docs.docker.com/compose/how-tos/production/ | Compose в продакшне | Use Compose in production

## 9.7 🔨 Production Hell 1: стек из пяти сервисов с пятью поломками | short: Production Hell | est: ~75 мин
### intro
**Слова шага:** *диагностика без подсказок*, *цепочка «клиент → сеть → порт → зависимость → данные»*.

:::tip Если совсем просто
Это **экзамен**, а не урок. Я нарочно ломаю кофейню в пяти местах, а ты — как детектив: идёшь от симптома к причине и чинишь. Ничего нового тут нет: **всё, что нужно, ты уже делала** в шагах 2–8. Подсказки и разбор лежат под спойлерами; открывай их только после честной попытки.
:::

Стек из пяти сервисов (`db`, `api`, `web`, `adminer`, `cache`) собран с **пятью поломками**. Твоя задача — добиться, чтобы `curl http://localhost:8080/api/menu` возвращал меню, а `docker compose ps` показывал все сервисы здоровыми. Готовим «аварийный» стек (сначала остановим предыдущий):

```bash run
cd ~/docker-lab/coffeeshop
docker compose -f compose.yaml -f compose.prod.yaml down
mkdir -p ~/docker-lab/hell && cd ~/docker-lab/hell
cat > .env <<'EOF'
DB_USER=coffee
EOF
cat > compose.yaml <<'EOF'
name: hell

services:
  db:
    image: postgres:18
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD:?нужен DB_PASSWORD}
      POSTGRES_DB: coffee
    volumes:
      - hellpg:/var/lib/postgresql/data
      - ../coffeeshop/db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d coffee"]
      interval: 2s
      timeout: 3s
      retries: 15
    networks: [back]

  api:
    build: ../coffeeshop/api
    environment:
      DB_HOST: localhost
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_NAME: coffee
    depends_on:
      db:
        condition: service_healthy
    networks: [back]

  web:
    build: ../coffeeshop/web
    ports:
      - "8080:8080"
    depends_on:
      - api
    networks: [front]

  adminer:
    image: adminer:5
    ports:
      - "127.0.0.1:8081:8080"
    networks: [back]

  cache:
    image: redis:8-alpine
    networks: [back]

networks:
  front:
  back:

volumes:
  hellpg:
EOF
ls -a
```

### result
```out auto
```

Папка `~/docker-lab/hell` готова: в ней `compose.yaml` и `.env`. **Правила игры:**

1. Меняй только `compose.yaml` и `.env` (код API и сайта правильный — он в `~/docker-lab/coffeeshop`).
2. Идёшь по одной поломке: запустил → увидела симптом → нашла причину → исправила → запустила снова.
3. Каждый раз начинай диагностику с одного и того же: **`docker compose ps -a`**, затем **`docker compose logs <сервис>`**, затем сеть и порты.
4. Финиш: `docker compose ps` — все сервисы `Up` (у `db` и ещё у кого есть `healthcheck` — `healthy`), `curl -s http://localhost:8080/api/menu` — список напитков из базы.

Начни с первого запуска:

```bash run
cd ~/docker-lab/hell
docker compose up -d 2>&1 | head -5
```

```out auto
```

Первая поломка встретила тебя сразу. Дальше — сама. Подсказки открывай по одной, **после** попытки:

### deep Подсказка 1: где искать (открыть, если застряла)
Поломки лежат в **пяти разных слоях**, и каждая видна по своему симптому: **1)** настройки и переменные (Compose отказывается запускать); **2)** хранение данных базы (PostgreSQL 18!); **3)** адрес базы в настройках API; **4)** сети между сайтом и API; **5)** публикация порта сайта. Порядок, в котором ты их встретишь, — примерно такой.

### deep Подсказка 2: симптомы по порядку (открыть, если застряла)
- `docker compose up -d` сразу пишет, что обязательная переменная не задана. → шаг 8.4 (интерполяция, `.env`).
- `db` — `Exited (1)`; в `logs` сказано про `/var/lib/postgresql/data`. → шаг 7.7.
- `api` падает при старте: `ECONNREFUSED 127.0.0.1:5432`. → шаг 6.3 (какое имя использовать вместо `localhost`).
- `curl http://localhost:8080/` — пустой ответ или «connection reset». → шаг 6.2 (какой порт у nginx внутри).
- `curl http://localhost:8080/api/menu` — `502 Bad Gateway`. → шаг 6.5–6.6 (в каких сетях сайт и API).

### deep Разбор: пять поломок и исправления (открыть после попытки)
**1. Не задан `DB_PASSWORD`** — `${DB_PASSWORD:?…}` остановил запуск. Лечение: добавить пароль в `.env`.
**2. Том PostgreSQL 18 смонтирован в старый путь** `/var/lib/postgresql/data` — образ отказывается стартовать. Лечение: `hellpg:/var/lib/postgresql`.
**3. `DB_HOST: localhost`** — внутри контейнера `api` свой `localhost`, базы там нет. Лечение: `DB_HOST: db`.
**4. `api` только в сети `back`, `web` только в `front`** — сайт не видит API (`502`). Лечение: подключить `api` и к `front`.
**5. `ports: "8080:8080"`** — nginx слушает порт **80** внутри контейнера. Лечение: `"8080:80"`.

Применим все исправления и проверим результат (команды выполнены в тестовой среде; у тебя их делаешь руками, редактируя файлы):

```bash run
cd ~/docker-lab/hell
docker compose down -v > /dev/null 2>&1
echo "DB_PASSWORD=secret" >> .env
sed -i 's#hellpg:/var/lib/postgresql/data#hellpg:/var/lib/postgresql#' compose.yaml
sed -i 's#DB_HOST: localhost#DB_HOST: db#' compose.yaml
sed -i 's#"8080:8080"#"8080:80"#' compose.yaml
awk 'BEGIN{svc=""} /^  api:/{svc="api"} /^  web:/{svc="web"} /^  adminer:/{svc="adminer"} svc=="api" && /networks: \[back\]/{sub(/\[back\]/,"[front, back]")} {print}' compose.yaml > compose.fixed.yaml
mv compose.fixed.yaml compose.yaml
docker compose up -d --build 2>&1 | tail -3
sleep 6
docker compose ps --format 'table {{.Service}}\t{{.Status}}'
curl -s -w '\n' http://localhost:8080/api/menu
docker compose down -v > /dev/null 2>&1
```

```out auto
```

После пяти исправлений все сервисы работают, а меню приходит из базы. Если ты нашла поломки сама, у тебя получился настоящий навык диагностики: **сверху вниз по слоям**, по одному симптому за раз, всегда начиная с `ps -a` и `logs`.

### why
В реальной работе поломки не подписаны: приходит сообщение «сайт не работает». Ты разбираешь цепочку по слоям (конфигурация, данные, адрес, сеть, порт), и каждое звено проверяется за минуту. Этому и учит «ад»: не знание отдельной команды, а привычка идти от симптома к причине.

### quiz
- Какими двумя командами ты начинаешь любую диагностику стека?
- Какие пять слоёв проверяла и какая поломка принадлежит каждому?
- Что ты изменила бы в процессе, чтобы ловить такие ошибки до запуска (подсказка: `docker compose config -q`, `.env.example`, `healthcheck`)?

### outro
:::tip Приёмка сессии 9
- Ты включаешь профили (`--profile`), подмешиваешь файлы (`-f`, `compose.override.yaml`) и знаешь правила слияния.
- Ты избегаешь повторов через `x-`, якоря, `extends` и `include`, не превращая файл в головоломку.
- Ты запускаешь `docker compose watch` и объясняешь отличие от bind mount.
- Ты знаешь `restart`, `mem_limit`, `logging`, `stop_grace_period` и показываешь, что сервис с лишней памятью получает `OOMKilled`.
- Ты объясняешь, почему сервис с фиксированным портом не масштабируется.
- CoffeeShop запускается в двух режимах: `docker compose up -d` (разработка) и `docker compose -f compose.yaml -f compose.prod.yaml up -d` (боевой).
- Production Hell 1 пройден: пять поломок найдены по симптомам и исправлены.
:::
