# Сессия 3 · Образы
dur: ~3,5 ч

## 3.1 Образ — это стопка слоёв | short: Образ и слои | est: ~30 мин
### intro
**Слова шага:** *слой (layer)*, *образ*, *слой записи*, *union filesystem*, *`docker history`*, *content-addressable*.

:::tip Если совсем просто
Образ — торт из слоёв: бисквит, крем, посыпка. Слои запечатаны. Когда ты берёшь кусок (запускаешь контейнер), сверху кладёшь свою тарелку (слой записи) — сам торт остаётся целым.
:::

```svg
<svg viewBox="0 0 640 275" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Образ как стопка слоёв и слой записи контейнера" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m6-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m6-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><text x="150" y="20" text-anchor="middle" font-size="14" font-weight="700" fill="currentColor" fill-opacity="1">Образ (только чтение)</text><rect x="40" y="34" width="220" height="40" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="150.0" y="59.0" text-anchor="middle" font-size="13" fill="currentColor">CMD / настройки образа</text><rect x="40" y="78" width="220" height="40" rx="8" fill="currentColor" fill-opacity="0.11000000000000001" stroke="currentColor" stroke-width="1.5"/><text x="150.0" y="103.0" text-anchor="middle" font-size="13" fill="currentColor">Твой код (COPY)</text><rect x="40" y="122" width="220" height="40" rx="8" fill="currentColor" fill-opacity="0.15000000000000002" stroke="currentColor" stroke-width="1.5"/><text x="150.0" y="147.0" text-anchor="middle" font-size="13" fill="currentColor">Установка пакетов (RUN)</text><rect x="40" y="166" width="220" height="40" rx="8" fill="currentColor" fill-opacity="0.19" stroke="currentColor" stroke-width="1.5"/><text x="150.0" y="191.0" text-anchor="middle" font-size="13" fill="currentColor">База: Alpine</text><text x="450" y="20" text-anchor="middle" font-size="14" font-weight="700" fill="currentColor" fill-opacity="1">Контейнер</text><rect x="340" y="34" width="220" height="40" rx="8" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="450.0" y="59.0" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor">Слой записи (можно менять)</text><rect x="340" y="78" width="220" height="36" rx="8" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-width="1.5"/><text x="450.0" y="101.0" text-anchor="middle" font-size="12" fill="currentColor">CMD / настройки образа</text><rect x="340" y="118" width="220" height="36" rx="8" fill="currentColor" fill-opacity="0.08" stroke="currentColor" stroke-width="1.5"/><text x="450.0" y="141.0" text-anchor="middle" font-size="12" fill="currentColor">Твой код (COPY)</text><rect x="340" y="158" width="220" height="36" rx="8" fill="currentColor" fill-opacity="0.11" stroke="currentColor" stroke-width="1.5"/><text x="450.0" y="181.0" text-anchor="middle" font-size="12" fill="currentColor">Установка пакетов (RUN)</text><rect x="340" y="198" width="220" height="36" rx="8" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.5"/><text x="450.0" y="221.0" text-anchor="middle" font-size="12" fill="currentColor">База: Alpine</text><line x1="262" y1="100" x2="338" y2="100" stroke="currentColor" stroke-width="1.8" marker-end="url(#m6-e)"/><text x="300" y="92" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">запуск</text><text x="150" y="255" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">слои запечатаны, как слои торта</text><text x="450" y="262" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">свою «тарелку» кладёшь сверху</text></svg>
```

Образ — не один большой файл. Он собран из **слоёв**: каждый слой — набор изменений файловой системы («добавили эти файлы», «удалили этот»). Слои складываются друг на друга, как прозрачные плёнки: сверху видно всё сразу, а под ними — остальные. После сборки слои **не меняются**: их можно только читать.

Когда Docker запускает контейнер, он кладёт поверх всех слоёв образа ещё один — **слой записи** (writable layer). Всё, что процесс в контейнере создаёт или меняет, попадает туда. Слои образа остаются нетронутыми, поэтому из одного образа можно запустить сотню контейнеров: у каждого свой тонкий слой записи, а слои образа общие. Вспомни `docker diff` из шага 2.5 — он как раз показывал содержимое слоя записи.

Посмотрим слои на живом образе. `docker history` показывает, из чего образ собран, сверху (самое новое) вниз:

```bash run
docker history nginx:1.30-alpine
```

### result
```out auto
```

Каждая строка — один слой (или инструкция, не создавшая файлов — у неё размер `0B`). Колонки: `CREATED BY` — какая инструкция его создала (`RUN`, `COPY`, `CMD` из будущего `Dockerfile`), `SIZE` — сколько он добавил. Нижние строки — база (Alpine), верхние — то, что наложил nginx: установка пакетов, конфиги, `CMD`.

У каждого слоя есть идентификатор — **хэш содержимого** (`sha256:…`): Docker считает контрольную сумму от файлов слоя. Одинаковое содержимое — одинаковый хэш. Это и называется *content-addressable* (адресуется содержимым). Увидеть хэши слоёв образа:

```bash run
docker image inspect --format '{{range .RootFS.Layers}}{{println .}}{{end}}' alpine
```

```out auto
```

У `alpine` один слой — вся система. Практическое следствие: если два образа начинаются с одинакового слоя (например, оба на Alpine), на диске этот слой лежит **один раз**, а при скачивании Docker напишет `Already exists` вместо повторной загрузки. Ты видела это в шаге 2.1: у nginx первый слой `a9986cd6f37d: Already exists` — тот самый слой Alpine, который уже был.

### why
Слои объясняют сразу три практических вещи. **Скорость:** неизменившийся слой берётся из кэша и не пересобирается (сессия 4). **Экономия места:** общие слои хранятся один раз. **Размер образа:** слой, добавивший файл, остаётся в образе, даже если следующий слой файл удалил, — потому что слои не меняются, а только накладываются. На этой ловушке построен шаг 3.7.

### deep Как это устроено под капотом
Раньше слои складывались драйвером `overlay2` (*union filesystem*: объединённая файловая система поверх нескольких папок). В Docker 29 по умолчанию используется хранилище на `containerd` (в `docker info` это `driver-type: io.containerd.snapshotter.v1`), но идея та же: список слоёв «только чтение» плюс один слой записи сверху. Если процесс изменяет файл из нижнего слоя, Docker сначала **копирует** его в слой записи (*copy-on-write*) и меняет копию.

### deep Команда по частям
`docker image inspect --format '{{range .RootFS.Layers}}{{println .}}{{end}}' alpine`: `image inspect` — подробности об образе; `.RootFS.Layers` — список хэшей слоёв; `range … end` — цикл Go-шаблона «для каждого элемента»; `println` — напечатать с переводом строки.

### quiz
- Из чего состоит образ и можно ли изменить слой после сборки?
- Что такое слой записи и когда он появляется?
- Почему два образа на одной базе занимают меньше места, чем сумма их размеров?

### links
- https://docs.docker.com/get-started/docker-concepts/building-images/understanding-image-layers/ | слои образа | Understanding image layers
- https://docs.docker.com/reference/cli/docker/image/history/ | docker history | docker history

## 3.2 Работа с образами: pull, tag, rmi, save, load | short: Команды для образов | est: ~40 мин
### intro
**Слова шага:** *имя образа*, *тег*, *`latest`*, *digest*, *`pull`*, *`tag`*, *`rmi`*, *`save`/`load`*, *`export`/`import`*.

:::tip Если совсем просто
Тег — ярлык на банке: его можно переклеить на другую банку. Digest — серийный номер, отпечаток самой банки: его не подделать.
:::

**Имя образа** состоит из частей: `[registry/][пользователь/]имя[:тег][@digest]`. Например, `nginx:1.30-alpine`: имя `nginx`, тег `1.30-alpine`. Без тега Docker подставляет **`latest`** — но это не «последняя версия», а просто тег с таким названием, и его обновляют, как хотят авторы. Поэтому в серьёзной работе всегда пишут конкретный тег.

**Digest** (`sha256:…`) — неизменный отпечаток образа: тег можно перенацелить на другой образ, а digest — нельзя. Если нужна гарантия «тот самый образ», используют `имя@sha256:…`.

Скачаем образ и посмотрим список. `docker pull` скачивает, `docker images` перечисляет (вспомни шаг 1.4):

```bash run
docker pull alpine:3.22
docker images alpine
```

### result
```out auto
```

Видны оба образа `alpine`: `3.22` и `latest`, которые на этот момент разные. Теперь **digest**. Достанем его и скачаем образ по отпечатку — это даёт строгую гарантию версии (`$(…)` ниже — подстановка оболочки: результат команды внутри становится значением переменной `D`):

```bash run
D=$(docker image inspect --format '{{index .RepoDigests 0}}' alpine:3.22)
echo "$D"
docker pull "$D"
```

```out auto
```

`Status: Image is up to date` — образ уже лежит на диске, и по digest Docker подтвердил, что это тот же.

**`docker tag`** добавляет образу ещё одно имя (образ не копируется, меняется только ссылка). Так образу дают собственное имя перед публикацией (сессия 10). **`docker rmi`** удаляет имя; сам образ исчезает, когда не осталось ни одного имени и ни одного контейнера:

```bash run
docker tag alpine:3.22 coffee/base:1
docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}' | grep -E 'REPOSITORY|alpine|coffee'
docker rmi coffee/base:1
docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}' | grep -E 'REPOSITORY|alpine|coffee'
```

```out auto
```

У `coffee/base:1` и `alpine:3.22` был один `IMAGE ID` — это один образ с двумя именами. После `rmi` осталось одно имя.

Образ можно упаковать в файл и перенести без интернета. **`docker save`** пишет в `.tar` образ вместе со слоями и тегами, **`docker load`** читает обратно:

```bash run
mkdir -p ~/docker-lab/s03 && cd ~/docker-lab/s03
docker save -o alpine.tar alpine:3.22
ls -lh alpine.tar
docker rmi alpine:3.22
docker load -i alpine.tar
docker images alpine
```

```out auto
```

Образ вернулся. Есть похожая пара **`export`/`import`**, но она другая: `docker export` выгружает *файловую систему контейнера* одним плоским архивом (без слоёв, тегов и `CMD`), а `import` превращает архив в новый образ из одного слоя. Для переноса образов нужна пара `save`/`load`; `export`/`import` нужна редко.

### why
Если запомнить одно: **тег — это подвижная метка, digest — неподвижный отпечаток**. Из-за этого в продакшне образы фиксируют конкретным тегом (`postgres:18`, а не `postgres`) или даже digest, а `latest` оставляют для экспериментов: сегодня он один, а через месяц — другая версия, и «ничего не менял, а сломалось».

### deep Как ещё можно
- **Формат имени из чужого registry:** `ghcr.io/org/app:1.0.0` — до первого `/` идёт адрес registry (`ghcr.io`); без адреса подразумевается Docker Hub.
- **Посмотреть все теги образа** можно на странице образа в Docker Hub, вкладка *Tags* (шаг 3.5); скачивать их все (`docker pull -a`) не надо.
- **Передать образ по SSH без registry:** `docker save имя | ssh сервер docker load` — просто труба.

### deep Если не получилось
- **`manifest for … not found`** — такого тега нет; проверь опечатку и список тегов на Docker Hub.
- **`image is being used by running container`** (при `rmi`) — есть контейнер из этого образа; удали его (`docker rm`) или добавь `-f`.
- **`docker load` — `no such file`** — запускаешь не из той папки; проверь `pwd` и `ls`.

### quiz
- Чем тег отличается от digest? Почему `latest` — ловушка?
- Что делает `docker tag` с образом: копирует его или нет?
- Чем `docker save` отличается от `docker export`?

### links
- https://docs.docker.com/reference/cli/docker/image/ | команды docker image | docker image
- https://docs.docker.com/reference/cli/docker/image/tag/ | docker tag | docker image tag

## 3.3 Увидеть слои: history, inspect, dive | short: Изучаем образ | est: ~25 мин
### intro
**Слова шага:** *`docker history`*, *`--no-trunc`*, *`docker image inspect`*, *`dive`*.

:::tip Если совсем просто
`history` — состав торта на упаковке: из чего сделан и сколько весит каждый слой.
:::

В шаге 3.1 мы смотрели `docker history`. Он, как рентген, показывает, **какая инструкция сколько весит**. Сравним с образом Postgres — тут хорошо видно, что тяжело:

```bash run
docker history --format 'table {{.CreatedBy}}\t{{.Size}}' postgres:18 | head -12
```

### result
```out auto
```

Колонка `CreatedBy` в таблице обрезана для читаемости; полный текст инструкций — с флагом `--no-trunc`. Видны большие слои (установка PostgreSQL и локалей) и крошечные (`CMD`, `ENV`, `EXPOSE`, у которых размер `0B` — они лишь меняют настройки образа).

`docker image inspect` показывает метаданные образа, а значит и то, **что запустится по умолчанию**. Достанем команду, рабочую папку, пользователя, порты (`{{"\n"}}` в шаблоне — перевод строки):

```bash run
docker image inspect --format 'Cmd={{json .Config.Cmd}}{{"\n"}}Entrypoint={{json .Config.Entrypoint}}{{"\n"}}WorkingDir={{.Config.WorkingDir}}{{"\n"}}User={{.Config.User}}{{"\n"}}Exposed={{json .Config.ExposedPorts}}' nginx:1.30-alpine
```

```out auto
```

`Entrypoint` + `Cmd` — то, с чего начнёт работать контейнер (сессия 4 подробно). Пустой `User` значит, что процесс запустится от **root**, а `WorkingDir=/` — что работа начнётся в корне. `ExposedPorts` — порты, которые образ *объявил* (но не открыл наружу: за это отвечает `-p`).

Для настоящего разбора есть программа **dive**: показывает слои образа и файлы в каждом, подсвечивает «пустую трату места». Установка на Mac: `brew install dive`, запуск: `dive nginx:1.30-alpine`. В Docker Desktop похожее есть во вкладке *Images*: образ открывается со слоями. В этой лабе обойдёмся `history`; когда образ вырастет (сессия 5), `dive` пригодится.

### why
Научиться «читать» чужой образ — значит перестать верить в «магию». Прежде чем взять образ с Docker Hub в свой проект, полезно посмотреть `history` и `inspect`: сколько он весит, от какого пользователя запускается, какие порты объявляет, что стоит у него по умолчанию.

### deep Команда по частям
`docker history --format 'table {{.CreatedBy}}\t{{.Size}}' postgres:18 | head -12`: `--format 'table …'` — вывод таблицей с нужными колонками; `\t` — разделитель; `| head -12` — оставить первые 12 строк, чтобы вывод не заполнил экран. `postgres:18` — образ.

### deep Если не получилось
- **Колонка `CreatedBy` обрезана** — это обычное поведение; добавь `--no-trunc`.
- **У слоёв `<missing>` вместо идентификатора** — для скачанных образов это нормально: слой принадлежит чужой сборке, и у твоего Docker нет для него «собственного» образа.

### quiz
- Как узнать, какая команда запустится в образе по умолчанию?
- Что означает размер `0B` у слоя в `docker history`?
- Что объявляет `ExposedPorts` и открывает ли он порт наружу?

### links
- https://github.com/wagoodman/dive | утилита dive | dive
- https://docs.docker.com/reference/cli/docker/image/inspect/ | docker image inspect | docker image inspect

## 3.4 Базовые образы: alpine, slim, distroless, scratch | short: Базовые образы | est: ~40 мин
### intro
**Слова шага:** *базовый образ*, *Alpine*, *musl*, *glibc*, *`slim`*, *distroless*, *`scratch`*.

:::tip Если совсем просто
Базовый образ — основа торта. Alpine — лёгкий бисквит, `slim` — обычный, полный — с кучей украшений. Distroless — торт без лишнего, там даже ножа нет.
:::

Свой образ почти всегда начинается со слов `FROM <база>` (шаг 3.6). От базы зависят размер, набор программ, безопасность и даже поведение приложения. Основные варианты:

- **Полный образ** (`node:24`, `debian:13`) — Debian с компилятором, утилитами и отладочными программами. Удобно, но гигантский, с большим числом лишних пакетов.
- **`slim`** (`node:24-slim`, `debian:13-slim`) — тот же Debian без «лишнего». Размер вдвое-втрое меньше.
- **`alpine`** (`node:24-alpine`, `alpine:3.22`) — крошечный Linux (~5 МБ) на библиотеке **musl** вместо привычной **glibc**. Почти всё работает, но редкие программы с нативными расширениями бывают несовместимы.
- **distroless** (`gcr.io/distroless/…`) — образы Google без оболочки и без менеджера пакетов: только твой запуск и необходимые библиотеки. Меньше поверхность атаки, но нельзя «зайти внутрь» через `sh`.
- **`scratch`** — пустой образ без единого файла. Годится только для полностью самодостаточных программ (Go). Образ `hello-world` из шага 1.4 собран именно на нём.

Сравним размеры. Скачаем несколько баз и выведем список (`-q` у `pull` убирает шум):

```bash run
docker pull -q node:24-alpine
docker pull -q node:24-slim
docker pull -q busybox:1.37
docker pull -q gcr.io/distroless/static-debian13
docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}' | grep -E 'REPOSITORY|alpine|slim|distroless|busybox'
```

### result
```out auto
```

(Список у тебя будет другим: в нём окажутся образы, которые уже были.) Колонка размера — это размер образа на диске; в `docker images` ты увидишь ещё колонку `CONTENT SIZE` — это «сжатый» размер, который скачивается из registry.

Теперь **musl против glibc** — главное различие между `alpine` и `slim`. Спросим у каждой системы, какая у неё стандартная библиотека C:

```bash run
docker run --rm alpine:3.22 sh -c 'ldd --version 2>&1 | head -1'
docker run --rm debian:13-slim sh -c 'ldd --version | head -1'
```

```out auto
```

Alpine сообщает `musl libc`, Debian — `GLIBC`. Программа, скомпилированная под glibc, **не запустится** на musl «как есть» — оттого бывают странные сообщения вроде `not found` про файл, который виден через `ls`. Пакеты Node и Python, использующие нативный код (`bcrypt`, `sharp`, часть научных библиотек), иногда требуют `slim`.

Распорядок «оболочка есть / нет» хорошо видно на distroless — в нём нет даже `sh`:

```bash run
docker run --rm gcr.io/distroless/static-debian13 sh
```

```out auto
```

Docker сообщает, что исполняемого файла `sh` в образе нет. Для сервиса это хорошо (атакующему нечем пользоваться), для отладки — неудобно.

:::tip Как выбирать базу
Начинай с `-alpine` для сервисов на Node, Go, Python: минимальный размер и быстрые сборки. Если упёрся в странную несовместимость библиотек — переходи на `-slim`. Distroless и `scratch` — следующий шаг, когда образ готов и важна безопасность (сессия 5).
:::

### why
Выбор базы — самое дешёвое решение, которое сильнее всего влияет на размер образа и безопасность. Чем меньше в образе пакетов, тем меньше в нём уязвимостей (сессия 5) и тем быстрее он скачивается на сервер. Но «меньше» не значит «лучше везде»: musl иногда ломает приложение, поэтому выбор — компромисс, а не правило.

### deep Distroless и scratch подробнее
У distroless нет `sh`, поэтому `docker exec -it … sh` не сработает: отлаживают такие контейнеры отдельным «отладочным» контейнером или командой `docker debug`. Есть варианты: `static` (для статически собранных программ, ~2 МБ), `base` (с glibc), `nodejs`, `python3` и т. д. Образ на `scratch` не содержит ничего — даже `/etc/passwd` и корневых сертификатов; программе приходится приносить всё своё.

### deep Если не получилось
- **`exec format error`** — запустила программу, собранную под другой процессор (образ `amd64` на ARM-Mac без эмуляции). Смотри архитектуру образа: `docker image inspect --format '{{.Architecture}}' имя`.
- **`not found` про файл, который виден через `ls`** — программа собрана под glibc, а запущена на musl (Alpine): нужна `slim`-база или сборка под musl.
- **В Alpine нет нужной программы** — в нём нет `bash`, `curl`; ставь пакетом: `apk add --no-cache curl`.

### quiz
- Чем `alpine` отличается от `slim`, кроме размера (какая библиотека C)?
- Зачем нужны distroless-образы и что в них нельзя сделать?
- На каком базовом образе собран `hello-world`?

### links
- https://hub.docker.com/_/alpine | образ Alpine | alpine
- https://github.com/GoogleContainerTools/distroless | образы distroless | distroless

## 3.5 Docker Hub: поиск и чтение страницы образа | short: Docker Hub | est: ~25 мин
### intro
**Слова шага:** *Docker Hub*, *official image*, *Verified Publisher*, *`docker search`*, *rate limit*, *тег-вариант*.

:::tip Если совсем просто
Docker Hub — магазин готовых коробок. «Official» — товар от самого производителя; всё остальное — от других продавцов, смотри отзывы.
:::

**Docker Hub** (`hub.docker.com`) — главное публичное хранилище образов. Там три категории:

- **Docker Official Images** — проверенные образы популярных программ (`nginx`, `postgres`, `node`, `alpine`): без префикса пользователя, с пометкой *Docker Official Image*.
- **Verified Publisher** — образы от коммерческих компаний (значок подтверждения).
- **Образы пользователей** — `пользователь/имя`; доверять им можно ровно настолько, насколько доверяешь автору.

Искать можно в браузере и из терминала. Колонка `OFFICIAL` с `[OK]` отмечает официальные образы:

```bash run
docker search --limit 4 postgres
```

### result
```out auto
```

(Числа звёзд у тебя будут свои.) Как читать страницу образа (например, `hub.docker.com/_/postgres`):

1. **Supported tags** — какие теги бывают: `18`, `18-alpine`, `18-trixie`. Вариант `-alpine` — на Alpine, `-trixie` или `-bookworm` — на Debian указанной версии. Всегда проверяй, какой именно тег берёшь.
2. **How to use this image** — готовые команды запуска и список переменных окружения (для Postgres — `POSTGRES_PASSWORD`).
3. **Environment Variables**, **Volumes** — какие настройки принимает образ и какой путь для данных (для PostgreSQL 18 — `/var/lib/postgresql`).
4. **Image Variants** — различия вариантов (`slim`, `alpine`).
5. **Tags → размер и архитектуры** — какие платформы (`linux/amd64`, `linux/arm64`) поддерживает образ.

**Лимиты.** Анонимные пользователи ограничены по числу скачиваний за 6 часов с одного IP; бесплатный аккаунт увеличивает лимит. Если встретила `toomanyrequests`, выполни `docker login`. Пароль вводится в интерактивном приглашении и сохраняется в хранилище ключей Mac; в файлы и команды его не пиши.

### why
Привычка «открыть страницу образа до `docker run`» экономит часы: на ней написано, какие переменные обязательны (как с `POSTGRES_PASSWORD` в шаге 2.7), куда монтировать данные и какие теги поддерживаются. Чужие образы — это чужой код, который будет работать у тебя; поэтому для баз и серверов бери Official, а остальное проверяй.

### deep Как ещё можно
- **GitHub Container Registry** (`ghcr.io`) и **Quay** (`quay.io`) — альтернативные публичные registry.
- **Зеркало Docker Hub в корпоративной сети** — настраивается в `daemon.json` (`registry-mirrors`).
- **Docker Hub в Docker Desktop** — поиск и загрузка образов доступны прямо в окне приложения, без терминала.

### deep Если не получилось
- **`docker search` пуст** — нет связи с Hub (прокси, VPN); проверь `curl -I https://hub.docker.com`.
- **`no matching manifest for linux/arm64/v8`** — образ не собран под Apple Silicon; можно запустить с эмуляцией `--platform linux/amd64` (медленнее).

### quiz
- Как отличить Docker Official Image от образа обычного пользователя?
- Какие четыре вещи стоит прочитать на странице образа до запуска?
- Что делать при `toomanyrequests`?

### links
- https://hub.docker.com/ | Docker Hub | hub.docker.com
- https://docs.docker.com/docker-hub/ | документация Docker Hub | Docker Hub docs

## 3.6 Первый Dockerfile из четырёх строк | short: Первый Dockerfile | est: ~35 мин
### intro
**Слова шага:** *`Dockerfile`*, *инструкция*, *`FROM`*, *`WORKDIR`*, *`COPY`*, *`CMD`*, *контекст сборки*, *`docker build`*, *кэш*.

:::tip Если совсем просто
Dockerfile — рецепт: каждая строка — одно действие. Docker запоминает результат каждого действия (кэш) и в следующий раз не повторяет то, что не изменилось.
:::

```svg
<svg viewBox="0 0 640 140" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="От Dockerfile до работающего контейнера" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m7-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m7-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><rect x="8" y="30" width="106" height="56" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="61.0" y="54.0" text-anchor="middle" font-size="13" fill="currentColor">Dockerfile</text><text x="61.0" y="72.0" text-anchor="middle" font-size="13" fill="currentColor">рецепт</text><line x1="114" y1="58" x2="132" y2="58" stroke="currentColor" stroke-width="1.8" marker-end="url(#m7-e)"/><rect x="132" y="30" width="106" height="56" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="185.0" y="54.0" text-anchor="middle" font-size="13" fill="currentColor">docker build</text><text x="185.0" y="72.0" text-anchor="middle" font-size="13" fill="currentColor">сборка</text><line x1="238" y1="58" x2="256" y2="58" stroke="currentColor" stroke-width="1.8" marker-end="url(#m7-e)"/><rect x="256" y="30" width="106" height="56" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="309.0" y="54.0" text-anchor="middle" font-size="13" fill="currentColor">Образ</text><text x="309.0" y="72.0" text-anchor="middle" font-size="13" fill="currentColor">коробка-набор</text><line x1="362" y1="58" x2="380" y2="58" stroke="currentColor" stroke-width="1.8" marker-end="url(#m7-e)"/><rect x="380" y="30" width="106" height="56" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="433.0" y="54.0" text-anchor="middle" font-size="13" fill="currentColor">docker run</text><text x="433.0" y="72.0" text-anchor="middle" font-size="13" fill="currentColor">запуск</text><line x1="486" y1="58" x2="504" y2="58" stroke="currentColor" stroke-width="1.8" marker-end="url(#m7-e)"/><rect x="504" y="30" width="106" height="56" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="557.0" y="54.0" text-anchor="middle" font-size="13" fill="currentColor">Контейнер</text><text x="557.0" y="72.0" text-anchor="middle" font-size="13" fill="currentColor">работает</text><text x="320" y="118" text-anchor="middle" font-size="13" fill="currentColor" fill-opacity="0.9">один рецепт → один образ → сколько угодно контейнеров</text></svg>
```

До сих пор мы запускали чужие образы. Теперь соберём свой. **`Dockerfile`** — текстовый файл-рецепт: каждая строка — инструкция, и каждая (изменяющая файлы) создаёт слой. Сделаем программу из одного файла. Создадим папку проекта и скрипт (`cat > файл <<'EOF' … EOF` — способ записать несколько строк в файл прямо из терминала; можно и создать файл в редакторе):

```bash run
mkdir -p ~/docker-lab/s03/hello && cd ~/docker-lab/s03/hello
cat > hello.sh <<'EOF'
#!/bin/sh
echo "Привет из контейнера! Я запущен как $(whoami) в $(pwd)"
EOF
cat hello.sh
```

```out auto
```

Теперь сам рецепт. Создай файл **`Dockerfile`** (без расширения) в той же папке:

```bash run
cat > Dockerfile <<'EOF'
FROM alpine:3.22
WORKDIR /app
COPY hello.sh .
CMD ["sh", "hello.sh"]
EOF
cat Dockerfile
```

```out auto
```

Четыре строки, четыре слова:

- **`FROM alpine:3.22`** — взять за основу этот образ. Каждый Dockerfile начинается с `FROM`.
- **`WORKDIR /app`** — рабочая папка внутри образа (создаётся, если нет); следующие инструкции и сам запуск идут «из» неё.
- **`COPY hello.sh .`** — скопировать файл `hello.sh` из **контекста сборки** (твоей папки) в текущую папку образа (`.` = `/app`).
- **`CMD ["sh", "hello.sh"]`** — команда по умолчанию при запуске контейнера. Квадратные скобки — *exec-форма* (запуск без оболочки, подробности в сессии 4).

Собираем. `docker build -t имя:тег .`: `-t` — дать образу имя, **`.` — контекст сборки**: папка, содержимое которой Docker отправляет демону для `COPY`. Точка значит «текущая папка». (`--progress=plain` печатает ход сборки обычным текстом — для чтения в методичке; на экране у тебя будет красивее, с полосками.)

```bash run
docker build --progress=plain -t hello:1 .
```

### result
```out auto
```

Каждая инструкция Dockerfile превратилась в шаг `#N`: загрузка метаданных базы, `WORKDIR`, `COPY`, запись образа (`exporting to image`). Запустим собранный образ:

```bash run
docker run --rm hello:1
```

```out auto
```

Скрипт отработал внутри контейнера: `root` — пользователь, `/app` — наша `WORKDIR`. Теперь покажем **кэш**: соберём ещё раз, ничего не меняя:

```bash run
docker build --progress=plain -t hello:1 . 2>&1 | grep -E 'CACHED|DONE|naming'
```

```out auto
```

Строки `CACHED` — шаги, которые Docker не выполнял заново, потому что вход (инструкция и файлы) тот же. Теперь изменим скрипт и соберём снова — кэш сломается ровно с места изменения (`COPY`), а `FROM`/`WORKDIR` останутся из кэша:

```bash run
echo 'echo "версия 2"' >> hello.sh
docker build --progress=plain -t hello:2 . 2>&1 | grep -E 'CACHED|DONE|naming'
docker run --rm hello:2
```

```out auto
```

### why
Это первый момент, когда видно главное правило Docker: **образ — это результат выполнения рецепта слой за слоем, а кэш работает по цепочке**. Если слой изменился, все слои после него пересобираются. Поэтому в Dockerfile редко меняющиеся вещи ставят выше, а часто меняющиеся (твой код) ниже — об этом вся следующая сессия.

### deep Что такое контекст сборки
Команда `docker build .` упаковывает всю папку `.` (контекст) и отправляет демону. Инструкция `COPY` может брать **только файлы из контекста** — и ничего за его пределами (`COPY ../file` не сработает). Лишние файлы (`node_modules`, `.git`) замедляют сборку: их исключают файлом `.dockerignore` (сессия 4).

### deep Как ещё можно
- **Другое имя файла:** `docker build -f Dockerfile.dev -t hello:dev .`.
- **Сборка без кэша:** `docker build --no-cache …`.
- **Собрать из репозитория:** `docker build https://github.com/user/repo.git#main`.

### deep Если не получилось
- **`failed to read dockerfile: open Dockerfile: no such file or directory`** — запускаешь не из той папки, или файл назвала не `Dockerfile`.
- **`COPY failed: file not found in build context`** — файл не лежит рядом с `Dockerfile` (или лежит вне контекста).
- **`unknown instruction`** — инструкция написана с опечаткой (`FORM`).

### quiz
- Что делает каждая из четырёх инструкций твоего Dockerfile?
- Что такое контекст сборки и что значит `.` в конце `docker build`?
- Почему при повторной сборке без изменений появляются строки `CACHED`?

### links
- https://docs.docker.com/reference/dockerfile/ | справочник Dockerfile | Dockerfile reference
- https://docs.docker.com/reference/cli/docker/buildx/build/ | docker build | docker build

## 3.7 🔨 Сломать → починить: образ «пухнет» | short: Раздувшийся образ | est: ~30 мин
### intro
**Слова шага:** *размер слоя*, *удалённый файл*, *`docker history`*, *склейка `RUN`*.

:::tip Если совсем просто
Нарисовал на бумаге, потом замазал — бумага всё равно толстая. Слои неизменяемы: «удалить» в новом слое — это просто замазать.
:::

Классическая ловушка: «я же удалил большой файл, почему образ всё равно огромный?» Воспроизведём. Создадим Dockerfile, который создаёт файл в 100 МБ (имитация скачанного архива) и следующей инструкцией удаляет его:

```bash run
mkdir -p ~/docker-lab/s03/fat && cd ~/docker-lab/s03/fat
cat > Dockerfile <<'EOF'
FROM alpine:3.22
RUN dd if=/dev/zero of=/big.bin bs=1M count=100
RUN rm /big.bin
EOF
docker build -q -t fat:1 .
docker images fat:1
```

### result
```out auto
```

Образ весит больше 100 МБ, хотя файла в нём нет. Найдём виновника, как договорились — `docker history`:

```bash run
docker history fat:1
```

```out auto
```

Видно: слой `RUN dd …` — 105 МБ, а слой `RUN rm /big.bin` — около 4 КБ. Слои неизменяемы: второй слой лишь **пометил** файл удалённым, а первый слой с 100 МБ остался в образе навсегда. Образ при запуске выглядит чистым, но скачивают его целиком.

**Починка.** Файл надо создать и удалить **в одном слое** — тогда в слой попадёт только итог (ничего):

```bash run
cd ~/docker-lab/s03/fat
cat > Dockerfile <<'EOF'
FROM alpine:3.22
RUN dd if=/dev/zero of=/big.bin bs=1M count=100 && rm /big.bin
EOF
docker build -q -t fat:2 .
docker images fat
```

```out auto
```

`fat:2` вернулся к размеру самой базы. Вывод для твоих Dockerfile: **скачал → распаковал → установил → убрал — всё одной инструкцией `RUN a && b && c`**. Типичный пример: `RUN apk add --no-cache curl` — флаг `--no-cache` не оставляет кэш пакетного менеджера в слое. Уберём за собой созданные образы:

```bash run
docker rmi fat:1 fat:2 hello:1 hello:2
docker images --format 'table {{.Repository}}\t{{.Tag}}' | grep -E 'REPOSITORY|fat|hello'
```

```out auto
```

(Осталась только строка заголовка: наши образы удалены.)

### why
Удаление файла в следующем слое **не уменьшает** образ. Это один из первых принципов, которые сразу окупаются: разбор «почему образ 1,5 ГБ» в реальных проектах почти всегда заканчивается словами «какой-то слой скачал и не убрал». В сессии 5 мы получим второй, ещё мощнее инструмент — multi-stage, где «мусор» сборки вообще не попадает в итоговый образ.

### deep Если не получилось
- **`dd: not found`** — используй образ `alpine` (в нём busybox-`dd`); в `scratch` его нет.
- **Размер `fat:2` не сильно изменился** — проверь, что оба действия в одной `RUN` через `&&`, а не двумя инструкциями.
- **`docker images fat` ничего не показывает** — после `rmi` образы исчезли; пересобери.

### quiz
- Почему удаление файла отдельной инструкцией не уменьшает размер образа?
- Как исправить Dockerfile, чтобы временный файл не попал в итоговый образ?
- Какая команда показывает, какой слой «раздул» образ?

### outro
:::tip Приёмка сессии 3
- Ты можешь объяснить, что образ — это стопка слоёв «только чтение», а контейнер добавляет к ней слой записи.
- Ты различаешь тег и digest, умеешь `pull`, `tag`, `rmi`, `save`/`load` и знаешь, чем плох `latest`.
- Ты умеешь прочитать `docker history` и `docker image inspect`, чтобы понять, из чего собран и как запускается чужой образ.
- Ты выбираешь базу (alpine / slim / distroless / scratch) и знаешь разницу musl и glibc.
- Образ из четырёх строк собран, запущен и пересобран с кэшем; найден и исправлен «раздутый» слой.
:::
