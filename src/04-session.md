# Сессия 4 · Dockerfile полностью
dur: ~4 ч

## 4.1 FROM, WORKDIR, COPY и ADD, RUN, EXPOSE | short: Основные инструкции | est: ~35 мин
### intro
**Слова шага:** *инструкция*, *`FROM`*, *`WORKDIR`*, *`COPY`*, *`ADD`*, *`RUN`*, *shell-форма*, *exec-форма*, *`EXPOSE`*.

:::tip Если совсем просто
Dockerfile — это инструкция к конструктору. `FROM` — «возьми вот такую коробку за основу». `WORKDIR` — «поставь стол вот здесь». `COPY` — «положи на стол мои детали». `RUN` — «сделай вот это при сборке». `CMD` — «а когда игрушку включат, пусть делает вот что».
:::

В шаге 3.6 мы написали четыре строки. Теперь разберём основные инструкции так, чтобы ты уверенно читала любой Dockerfile.

- **`FROM образ:тег`** — первая инструкция, база образа. Можно писать несколько `FROM` в одном файле (multi-stage, сессия 5).
- **`WORKDIR /путь`** — рабочая папка для всех следующих инструкций и для запуска. Создаётся автоматически. Лучше, чем `RUN cd …`: `cd` действует только внутри одной `RUN`.
- **`COPY откуда куда`** — копирует файлы **из контекста сборки** (твоей папки) в образ.
- **`ADD откуда куда`** — то же, но умеет ещё две вещи: распаковывать локальные архивы (`.tar.gz`) и скачивать по URL. Из-за «магии» его используют редко: по умолчанию бери `COPY`.
- **`RUN команда`** — выполняет команду **во время сборки** и сохраняет результат в слой (установка пакетов, сборка).
- **`EXPOSE порт`** — документирует, какой порт слушает приложение. Это подсказка людям и инструментам, порт наружу она **не открывает** (это делает `-p`).

Проверим различие `COPY` и `ADD` и двух форм команды на маленьком примере. Подготовим файлы: текстовый файл и архив с ним:

```bash run
mkdir -p ~/docker-lab/s04/basics && cd ~/docker-lab/s04/basics
echo "эспрессо" > menu.txt
tar czf bundle.tar.gz menu.txt
cat > Dockerfile <<'EOF'
FROM alpine:3.22
WORKDIR /srv
COPY menu.txt ./copy/
ADD bundle.tar.gz ./added/
RUN echo "собрано при сборке образа" > built.txt
CMD echo "shell-форма: HOME=$HOME"
EOF
docker build -q -t basics:1 .
docker run --rm basics:1 sh -c 'find /srv -type f | sort; cat /srv/built.txt'
```

### result
```out auto
```

Видно: `COPY menu.txt ./copy/` положил файл как есть (`/srv/copy/menu.txt`), а `ADD bundle.tar.gz ./added/` **сам распаковал** архив (`/srv/added/menu.txt` — внутри лежит файл, а не архив). Файл `built.txt` создала инструкция `RUN` при сборке: `RUN` сработала один раз, во время `docker build`, и запомнилась в слое.

Теперь **две формы** команды. **Shell-форма** — просто текст (`CMD echo "…"`): Docker запускает `/bin/sh -c "текст"`, поэтому работают переменные и конвейеры. **Exec-форма** — список в квадратных скобках (`CMD ["echo", "…"]`): программа запускается напрямую, без оболочки, и `$HOME` **не подставляется**. Соберём второй вариант:

```bash run
cd ~/docker-lab/s04/basics
cat > Dockerfile.exec <<'EOF'
FROM alpine:3.22
CMD ["echo", "exec-форма: HOME=$HOME"]
EOF
docker build -q -f Dockerfile.exec -t basics:exec .
docker run --rm basics:1
docker run --rm basics:exec
```

```out auto
```

В первом ответе `HOME=/root` подставлен оболочкой, во втором — буквально `$HOME`, потому что оболочки нет. Для постоянных сервисов выбирают **exec-форму**: у неё правильно работают сигналы (шаг 4.3). Для разовых команд со всякими `&&` и `$VAR` — shell-форму.

### why
Три различия, которые стоит запомнить: `COPY` вместо `ADD` (меньше магии), `WORKDIR` вместо `cd` (работает для всех следующих строк) и exec-форма для запуска (сигналы доходят до приложения). Остальное — вопрос вкуса.

### deep Как ещё можно
- **Скопировать только часть:** `COPY src/ ./src/`, `COPY *.json ./` (маски поддерживаются).
- **Сменить владельца при копировании:** `COPY --chown=node:node . .`.
- **Выставить права при копировании:** `COPY --chmod=755 script.sh ./` (нужен BuildKit, он включён по умолчанию).
- **Несколько команд в одном слое:** `RUN apk add --no-cache curl && curl --version` (шаг 3.7: одна `RUN` — один слой).

### deep Если не получилось
- **`COPY failed: file not found in build context`** — путь указан относительно контекста (папки, откуда запускаешь `docker build`), а не относительно `Dockerfile` где-то глубже.
- **`ADD` не распаковал архив** — распаковывается только локальный `.tar`, `.tar.gz` и т. п.; `.zip` не распаковывается.
- **`$HOME` напечатался буквально** — ты в exec-форме; если нужна подстановка, используй `["sh", "-c", "echo $HOME"]`.

### quiz
- Чем `COPY` отличается от `ADD` и какую из них брать по умолчанию?
- Чем shell-форма `CMD` отличается от exec-формы? Какая из них не подставит `$HOME`?
- Открывает ли `EXPOSE 3000` порт наружу?

### links
- https://docs.docker.com/reference/dockerfile/ | справочник Dockerfile | Dockerfile reference
- https://docs.docker.com/build/building/best-practices/ | рекомендации по Dockerfile | Dockerfile best practices

## 4.2 ENV, ARG, LABEL, USER, HEALTHCHECK и остальное | short: Остальные инструкции | est: ~40 мин
### intro
**Слова шага:** *`ENV`*, *`ARG`*, *`LABEL`*, *`USER`*, *`VOLUME`*, *`HEALTHCHECK`*, *`STOPSIGNAL`*, *`SHELL`*.

:::tip Если совсем просто
`ENV` — записка, которая остаётся у игрушки и после сборки. `ARG` — записка только для сборщика: игрушку собрали, записку выбросили. `USER` — «не работай под директором, работай обычным сотрудником». `HEALTHCHECK` — каждые несколько секунд спрашивать «ты жив?».
:::

Остальные инструкции:

- **`ENV имя=значение`** — переменная окружения, которая есть **и при сборке, и в запущенном контейнере**.
- **`ARG имя=по_умолчанию`** — переменная **только на время сборки** (передаётся `--build-arg`); в готовом контейнере её нет.
- **`LABEL ключ=значение`** — метаданные образа (автор, версия, ссылка на репозиторий).
- **`USER имя`** — от кого запускаются следующие инструкции и сам процесс. Без неё — от `root` (шаг 1.5).
- **`VOLUME /путь`** — объявляет папку для данных, которая должна жить вне контейнера (сессия 7).
- **`HEALTHCHECK`** — команда, которую Docker периодически запускает внутри контейнера, чтобы понять, жив ли сервис.
- **`STOPSIGNAL`** — какой сигнал слать при `docker stop` (по умолчанию SIGTERM).
- **`SHELL ["bash", "-c"]`** — какая оболочка используется для shell-формы.

Проверим на практике три из них: `ARG` против `ENV`, `USER` и `HEALTHCHECK`. Создадим Dockerfile:

```bash run
mkdir -p ~/docker-lab/s04/instr && cd ~/docker-lab/s04/instr
cat > Dockerfile <<'EOF'
FROM alpine:3.22
ARG VERSION=dev
ENV APP_ENV=production
LABEL org.opencontainers.image.title="coffee-demo" \
      org.opencontainers.image.version="$VERSION"
RUN echo "версия сборки: $VERSION" > /version.txt
USER nobody
HEALTHCHECK --interval=3s --timeout=2s --retries=2 \
  CMD test -f /version.txt || exit 1
CMD ["sh", "-c", "cat /version.txt; echo \"APP_ENV=$APP_ENV VERSION=${VERSION:-не задана}\"; echo \"работаю от: $(id -un)\"; sleep 30"]
EOF
docker build -q --build-arg VERSION=1.2.3 -t instr:1 .
docker run -d --name instr1 instr:1
sleep 5
docker logs instr1
```

### result
```out auto
```

Построчно. `версия сборки: 1.2.3` — `ARG` была видна **во время сборки** (команда `RUN` её использовала). `APP_ENV=production` — `ENV` доступна и в запущенном контейнере. `VERSION=не задана` — а вот `ARG` в готовом контейнере **нет**: её значение осталось только в слое. `работаю от: nobody` — сработал `USER`: процесс не root. Теперь метки и здоровье:

```bash run
docker inspect --format '{{json .Config.Labels}}' instr1
docker ps --format 'table {{.Names}}\t{{.Status}}'
docker inspect --format 'здоровье: {{.State.Health.Status}}' instr1
```

```out auto
```

В `STATUS` появилась приписка `(healthy)`: Docker каждые 3 секунды запускал `test -f /version.txt` и получал «успех». Если команда проверки будет падать `retries` раз подряд, статус станет `(unhealthy)`. Позже (сессия 8) `depends_on` научится ждать именно `healthy`, а не просто «запущен». Уберём за собой:

```bash run
docker rm -f instr1
```

```out auto
```

:::trap ARG и секреты
Не передавай пароли и токены через `ARG` или `ENV`: значения остаются в истории слоёв (`docker history`) и видны любому, кто получит образ. Для секретов сборки есть `RUN --mount=type=secret` (сессия 5), а для работы контейнера — переменные при запуске и секреты Compose (сессия 8).
:::

### why
Разница между `ARG` и `ENV` — одна из самых частых путаниц. Правило: **`ARG` — для сборки, `ENV` — для работы**. `USER` стоит ставить почти всегда: если в контейнере что-то взломают, у взломщика будут права обычного пользователя, а не root. `HEALTHCHECK` превращает «процесс запущен» в «сервис отвечает».

### deep Команда по частям
`HEALTHCHECK --interval=3s --timeout=2s --retries=2 CMD test -f /version.txt || exit 1`: `--interval` — как часто проверять; `--timeout` — сколько ждать ответа команды; `--retries` — сколько неудач подряд считать «unhealthy»; после `CMD` — сама проверка (код выхода `0` — здорово, `1` — нет). Для веб-сервиса обычно `CMD wget -qO- http://localhost:3000/health || exit 1`.

### deep Если не получилось
- **`VERSION` пуст в сборке** — флаг `--build-arg VERSION=…` написан после имени папки `.` или без `ARG` в Dockerfile (без объявления `ARG` аргумент игнорируется).
- **`permission denied` после `USER`** — пользователь не имеет прав на нужные файлы; права выставляют до `USER` (`COPY --chown=…`, `RUN chown …`).
- **Статус `(health: starting)` долго** — проверка ещё не прошла первый интервал; подожди.

### quiz
- В чём разница между `ARG` и `ENV` и почему нельзя передавать секреты через них?
- Что покажет `docker ps` у контейнера с `HEALTHCHECK` и чем это лучше статуса `Up`?
- Зачем ставить `USER` и от кого процесс запускается без неё?

### links
- https://docs.docker.com/reference/dockerfile/#healthcheck | HEALTHCHECK | Dockerfile HEALTHCHECK
- https://docs.docker.com/reference/dockerfile/#arg | ARG | Dockerfile ARG

## 4.3 ENTRYPOINT и CMD: четыре сочетания | short: ENTRYPOINT и CMD | est: ~40 мин
### intro
**Слова шага:** *`ENTRYPOINT`*, *`CMD`*, *exec-форма*, *shell-форма*, *PID 1*, *`exec`*, *SIGTERM*.

:::tip Если совсем просто
`ENTRYPOINT` — это **что делает** игрушка, когда её включили (например, «варить кофе»). `CMD` — **с чем по умолчанию** (например, «эспрессо»). Хочешь другой напиток — говоришь `docker run … латте`, и заменится только `CMD`, а варить всё равно будет кофемашина.
:::

`ENTRYPOINT` и `CMD` вместе определяют, какая команда запустится в контейнере. Правило: итоговая команда = **`ENTRYPOINT` + `CMD`**, причём `CMD` — это «аргументы по умолчанию», которые заменяются тем, что ты пишешь после имени образа в `docker run`.

| | нет `ENTRYPOINT` | есть `ENTRYPOINT` |
|---|---|---|
| **нет `CMD`** | нечего запускать — ошибка | запускается `ENTRYPOINT` |
| **есть `CMD`** | запускается `CMD` | запускается `ENTRYPOINT` + `CMD` как аргументы |

Проверим сочетание «есть оба»:

```bash run
mkdir -p ~/docker-lab/s04/ep && cd ~/docker-lab/s04/ep
cat > Dockerfile <<'EOF'
FROM alpine:3.22
ENTRYPOINT ["echo", "заказ:"]
CMD ["эспрессо"]
EOF
docker build -q -t ep:1 .
docker run --rm ep:1
docker run --rm ep:1 латте с овсяным молоком
docker run --rm --entrypoint echo ep:1 "полностью другая команда"
```

### result
```out auto
```

Первый запуск: `ENTRYPOINT` + `CMD` = `echo заказ: эспрессо`. Второй: после имени образа ты написала свои слова — они **заменили `CMD`**, а `ENTRYPOINT` остался. Третий: флаг `--entrypoint` заменил `ENTRYPOINT` (и вместе с ним сбросил `CMD`, поэтому остались только твои слова). Обычное разделение ролей: **`ENTRYPOINT` — «что это за программа»**, **`CMD` — «аргументы по умолчанию»**.

Теперь почему форма (exec или shell) важна для остановки. Помнишь шаг 2.6: `docker stop` шлёт SIGTERM **процессу с PID 1**. При exec-форме `CMD ["node", "server.js"]` PID 1 — это `node`. При shell-форме `CMD node server.js` PID 1 — это `/bin/sh -c "node server.js"`, а `node` — его ребёнок, и сигнал до него может не дойти. Поэтому для сервисов нужна exec-форма. Увидим это в шаге 4.6 на настоящем API.

```svg
<svg viewBox="0 0 640 230" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="PID 1: сигнал доходит до приложения только если оно главный процесс" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m1-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m1-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><text x="160" y="20" text-anchor="middle" font-size="14" font-weight="700" fill="currentColor" fill-opacity="1">Без exec: скрипт — PID 1</text><text x="480" y="20" text-anchor="middle" font-size="14" font-weight="700" fill="currentColor" fill-opacity="1">С exec: приложение — PID 1</text><rect x="60" y="40" width="200" height="40" rx="8" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.5"/><text x="160.0" y="65.0" text-anchor="middle" font-size="13" fill="currentColor">PID 1: entrypoint.sh</text><rect x="80" y="100" width="160" height="40" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="160.0" y="125.0" text-anchor="middle" font-size="13" fill="currentColor">PID 7: node</text><line x1="160" y1="80" x2="160" y2="100" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)"/><text x="160" y="160" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.9">docker stop шлёт SIGTERM скрипту</text><text x="160" y="178" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.9">скрипт молчит → через 10 с SIGKILL (137)</text><rect x="380" y="40" width="200" height="40" rx="8" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.5"/><text x="480.0" y="65.0" text-anchor="middle" font-size="13" fill="currentColor">PID 1: node</text><text x="480" y="110" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">(скрипт заменил себя на node</text><text x="480" y="126" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">командой exec)</text><text x="480" y="160" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.9">docker stop шлёт SIGTERM node</text><text x="480" y="178" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.9">node закрывается сам, код 0</text></svg>
```

### why
Если помнить только одно: **пиши `CMD` и `ENTRYPOINT` в exec-форме (в квадратных скобках)**, чтобы `docker stop` останавливал приложение за доли секунды, а не за 10 секунд с кодом 137. А `ENTRYPOINT` + `CMD` пригодятся для образов, которые ведут себя как «команда с параметрами» (как `docker run postgres:18 postgres -c max_connections=200`).

### deep Как ещё можно
- **Shell-форма `ENTRYPOINT`** (`ENTRYPOINT echo заказ:`) запускает через `sh -c` и **игнорирует** `CMD` и аргументы `docker run` — почти всегда не то, что нужно.
- **Переопределить всё при отладке:** `docker run --rm -it --entrypoint sh образ` — зайти в образ в обход обычного запуска (шаг 2.7).
- **Посмотреть, что записано в образе:** `docker image inspect --format '{{json .Config.Entrypoint}} {{json .Config.Cmd}}' ep:1`.

### deep Если не получилось
- **`exec: "...": executable file not found in $PATH`** — в `ENTRYPOINT` или `CMD` указана программа, которой нет в образе (или опечатка).
- **`permission denied` при запуске скрипта-entrypoint** — у скрипта нет права на выполнение: `COPY --chmod=755 entrypoint.sh ./` или `RUN chmod +x entrypoint.sh`.
- **Аргументы `docker run` «не доходят»** — в Dockerfile `ENTRYPOINT` в shell-форме; перепиши в exec-форму.

### quiz
- Что запустится, если в Dockerfile есть `ENTRYPOINT ["echo"]` и `CMD ["привет"]`, а ты вызвала `docker run образ мир`?
- Почему для сервиса лучше exec-форма, чем shell-форма?
- Чем `--entrypoint` отличается от слов после имени образа?

### links
- https://docs.docker.com/reference/dockerfile/#entrypoint | ENTRYPOINT | Dockerfile ENTRYPOINT
- https://docs.docker.com/reference/dockerfile/#understand-how-cmd-and-entrypoint-interact | как взаимодействуют CMD и ENTRYPOINT | CMD and ENTRYPOINT

## 4.4 Кэш сборки и .dockerignore | short: Кэш и .dockerignore | est: ~35 мин
### intro
**Слова шага:** *кэш слоёв*, *порядок инструкций*, *контекст сборки*, *`.dockerignore`*.

:::tip Если совсем просто
Когда ты печёшь пирог по рецепту, а в середине поменяла начинку, всё, что идёт **после** начинки, придётся печь заново; всё, что было **до** неё, берётся готовым. Поэтому «то, что меняется чаще всего» ставят в рецепте как можно **ниже**.
:::

Правило кэша из шага 3.6: Docker перепроверяет инструкции сверху вниз; пока вход слоя тот же, берёт его из кэша; с первого изменившегося слоя пересобирает **всё, что ниже**. Для `COPY` «вход» — содержимое копируемых файлов: изменился хоть один байт — слой (и все следующие) пересоберутся.

```svg
<svg viewBox="0 0 640 300" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Кэш слоёв: правка кода пересобирает слои после неё" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m2-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m2-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><text x="160" y="20" text-anchor="middle" font-size="14" font-weight="700" fill="currentColor" fill-opacity="1">Плохой порядок</text><text x="480" y="20" text-anchor="middle" font-size="14" font-weight="700" fill="currentColor" fill-opacity="1">Хороший порядок</text><rect x="30" y="34" width="260" height="50" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="160.0" y="55.0" text-anchor="middle" font-size="13" fill="currentColor">FROM node</text><text x="160.0" y="73.0" text-anchor="middle" font-size="13" fill="currentColor">из кэша</text><rect x="30" y="92" width="260" height="50" rx="8" fill="currentColor" fill-opacity="0.22" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="160.0" y="113.0" text-anchor="middle" font-size="13" fill="currentColor">COPY . .  (весь код)</text><text x="160.0" y="131.0" text-anchor="middle" font-size="13" fill="currentColor">изменился → заново</text><rect x="30" y="150" width="260" height="50" rx="8" fill="currentColor" fill-opacity="0.22" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="160.0" y="171.0" text-anchor="middle" font-size="13" fill="currentColor">RUN npm ci</text><text x="160.0" y="189.0" text-anchor="middle" font-size="13" fill="currentColor">заново (долго!)</text><rect x="350" y="34" width="260" height="50" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="480.0" y="55.0" text-anchor="middle" font-size="13" fill="currentColor">FROM node</text><text x="480.0" y="73.0" text-anchor="middle" font-size="13" fill="currentColor">из кэша</text><rect x="350" y="92" width="260" height="50" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="480.0" y="113.0" text-anchor="middle" font-size="13" fill="currentColor">COPY package*.json</text><text x="480.0" y="131.0" text-anchor="middle" font-size="13" fill="currentColor">из кэша</text><rect x="350" y="150" width="260" height="50" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="480.0" y="171.0" text-anchor="middle" font-size="13" fill="currentColor">RUN npm ci</text><text x="480.0" y="189.0" text-anchor="middle" font-size="13" fill="currentColor">из кэша</text><rect x="350" y="208" width="260" height="50" rx="8" fill="currentColor" fill-opacity="0.22" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="480.0" y="229.0" text-anchor="middle" font-size="13" fill="currentColor">COPY server.js</text><text x="480.0" y="247.0" text-anchor="middle" font-size="13" fill="currentColor">изменился → заново</text><text x="160" y="245" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">после изменённого слоя всё заново</text><text x="480" y="275" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">пересобирается только последний слой</text></svg>
```

На схеме слева код копируется **до** установки зависимостей: любая правка кода сбрасывает кэш и снова запускает долгую `npm ci`. Справа сначала копируются только файлы зависимостей, потом ставятся пакеты, и лишь затем копируется код — пакеты переустанавливаются только когда изменился `package.json`. Мы проверим это на настоящем API в шаге 4.7.

Вторая часть шага — **контекст сборки** (шаг 3.6). `docker build .` упаковывает всю папку и отправляет демону, даже если большая часть не нужна. Покажем это: положим в папку «тяжёлый мусор» (50 МБ) и посмотрим на отправку контекста:

```bash run
mkdir -p ~/docker-lab/s04/ctx && cd ~/docker-lab/s04/ctx
dd if=/dev/urandom of=junk.bin bs=1M count=50 2>/dev/null
echo "hello" > app.txt
printf 'FROM alpine:3.22\nCOPY . /ctx/\n' > Dockerfile
docker build --progress=plain -t ctx:1 . 2>&1 | grep -A1 'load build context'
```

### result
```out auto
```

`COPY . /ctx/` копирует «всё из папки», поэтому демону уехал весь контекст, включая 50 МБ мусора (в выводе — размер около 50 МБ). Современный BuildKit умный: если бы мы копировали только `app.txt`, он отправил бы лишь его; но `COPY . .` встречается в большинстве Dockerfile, и тогда в контекст едет всё. Создадим **`.dockerignore`** — список того, что в контекст не попадает (синтаксис как у `.gitignore`):

```bash run
cd ~/docker-lab/s04/ctx
printf 'junk.bin\nnode_modules\n.git\n*.log\n.env\n' > .dockerignore
docker build --progress=plain -t ctx:2 . 2>&1 | grep -A1 'load build context'
```

```out auto
```

Теперь контекст — несколько байт: `junk.bin` в него не попал. На реальных проектах разница между секундами и минутами: без `.dockerignore` в контекст едут `node_modules` (сотни мегабайт), `.git` и логи. Стандартный набор для Node-проекта: `node_modules`, `.git`, `*.log`, `.env`, `Dockerfile`, `.dockerignore`. Отдельная польза: файлы вроде `.env` с секретами **не попадают** в образ, даже если кто-то напишет `COPY . .`.

### why
Скорость сборки на 90% зависит от двух вещей: порядка инструкций (кэш) и чистоты контекста (`.dockerignore`). Обе правки бесплатные, и обе дают самый заметный выигрыш: пересборка после правки кода превращается из минуты в секунду.

### deep Команда по частям
`docker build --progress=plain -t ctx:1 . 2>&1 | grep 'transferring context'`: `--progress=plain` — вывод обычным текстом; `2>&1` — склеить сообщения об ошибках с обычным выводом; `| grep -A1` — оставить строки с нужным текстом и одну следующую за ней. `load build context` и следующая строка `transferring context: …` — сколько данных ушло демону.

### deep Как ещё можно
- **Разрешить только нужное:** `.dockerignore` из двух строк: `*` и `!app.txt` — «исключить всё, кроме `app.txt`» (подход «белого списка»).
- **Смотреть, что попало в контекст:** `docker build` с `--progress=plain` показывает объём, а в `COPY . /ctx` + `ls -R` — состав.
- **Принудительно сбросить кэш одного слоя:** изменить строку (например, добавить `ARG CACHE_BUST`) или `docker build --no-cache`.

### deep Если не получилось
- **`.dockerignore` не работает** — файл должен лежать в **корне контекста** (рядом с папкой, указанной в `docker build`), а имя — ровно `.dockerignore`.
- **`COPY` не находит файл, который ты исключила** — так и задумано: исключённое в контексте не существует.
- **Кэш не сработал, хотя ничего не менялось** — выше по Dockerfile стоит инструкция, которая каждый раз разная (например, `ADD` по URL, `ARG` со временем или `COPY . .` с изменившейся мелочью вроде `.git`).

### quiz
- Почему `COPY package.json` и `RUN npm ci` ставят **до** `COPY . .`?
- Что делает `.dockerignore` и зачем в него добавляют `.env` и `node_modules`?
- Что происходит с кэшем всех слоёв ниже изменившегося?

### links
- https://docs.docker.com/build/cache/ | кэш сборки | Build cache
- https://docs.docker.com/build/concepts/context/#dockerignore-files | .dockerignore | .dockerignore files

## 4.5 Контейнеризируем CoffeeShop API | short: CoffeeShop API в образ | est: ~50 мин
### intro
**Слова шага:** *Node.js*, *`package.json`*, *`package-lock.json`*, *`npm ci`*, *`USER node`*, *сквозной проект*.

:::tip Если совсем просто
До сих пор мы пекли пробные булочки. Теперь печём настоящий торт — **CoffeeShop**, наш главный проект на всю лабу. Сначала пишем маленький сервер «меню кофейни», потом упаковываем его в коробку (образ), и коробка запускается где угодно одинаково.
:::

Наш сквозной проект — CoffeeShop: API на Node.js, потом сайт на nginx, база PostgreSQL и Adminer. Начнём с API: сервер на Express с двумя адресами — `/health` («жив ли сервис») и `/menu` (список напитков). Node и npm на Mac ставить не надо: всё будет внутри контейнеров.

Создадим папку проекта и два файла. `package.json` — описание проекта и его зависимостей; `server.js` — сам сервер.

```bash run
mkdir -p ~/docker-lab/coffeeshop/api && cd ~/docker-lab/coffeeshop/api
cat > package.json <<'EOF'
{
  "name": "coffeeshop-api",
  "version": "1.0.0",
  "type": "module",
  "private": true,
  "scripts": { "start": "node server.js" },
  "dependencies": { "express": "^5.1.0" }
}
EOF
cat > server.js <<'EOF'
import express from 'express'

const app = express()
const port = process.env.PORT || 3000

const menu = [
  { id: 1, name: 'Эспрессо', price: 150 },
  { id: 2, name: 'Капучино', price: 220 },
  { id: 3, name: 'Латте', price: 250 },
]

app.get('/health', (req, res) => res.json({ status: 'ok' }))
app.get('/menu', (req, res) => res.json(menu))

const server = app.listen(port, () => console.log(`CoffeeShop API слушает порт ${port}`))

process.on('SIGTERM', () => {
  console.log('получен SIGTERM, закрываюсь')
  server.close(() => process.exit(0))
})
EOF
ls
```

### result
```out auto
```

Что в `server.js`: создаём приложение Express, описываем два адреса, слушаем порт (`PORT` из переменной окружения, по умолчанию 3000) и обрабатываем SIGTERM — закрываем сервер аккуратно (шаг 2.6). Для воспроизводимой сборки нужен файл **`package-lock.json`** — он фиксирует точные версии всех пакетов. Его создаёт `npm`, но ставить Node на Mac не хочется — используем контейнер Node как «одноразовый инструмент». Флаг `-v "$PWD":/app` монтирует текущую папку внутрь контейнера (подробно — сессия 7), `-w /app` задаёт рабочую папку, `--package-lock-only` создаёт только файл блокировки, без `node_modules`:

```bash run
cd ~/docker-lab/coffeeshop/api
docker run --rm -v "$PWD":/app -w /app node:24-alpine npm install --package-lock-only --no-fund --no-audit --loglevel=error
ls
```

```out auto
```

Появился `package-lock.json` (строки `npm notice` про новую версию npm — просто реклама, их можно игнорировать). Теперь Dockerfile — с хорошим порядком слоёв (шаг 4.4) и без root (шаг 4.2). Образ `node:24-alpine` уже содержит пользователя `node` без особых прав. И `.dockerignore`:

```bash run
cd ~/docker-lab/coffeeshop/api
cat > Dockerfile <<'EOF'
FROM node:24-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY server.js ./
USER node
EXPOSE 3000
CMD ["node", "server.js"]
EOF
printf 'node_modules\n.git\n*.log\n.env\nDockerfile\n.dockerignore\n' > .dockerignore
docker build -q -t coffee-api:1 .
docker images coffee-api
```

```out auto
```

Что делает каждая строка: **`COPY package.json package-lock.json ./`** — только файлы зависимостей; **`RUN npm ci --omit=dev`** — установить ровно те версии, что записаны в `package-lock.json` (`ci` — чистая установка, быстрее и строже, чем `install`; `--omit=dev` — без пакетов для разработки); **`COPY server.js ./`** — код (после зависимостей!); **`USER node`** — работаем без root; **`CMD ["node", "server.js"]`** — exec-форма. Запускаем (`-p 3000:3000` — порт хоста : порт контейнера) и проверяем:

```bash run
docker run -d --name api -p 3000:3000 coffee-api:1
sleep 2
curl -s -w '\n' http://localhost:3000/health
curl -s -w '\n' http://localhost:3000/menu
docker exec api id -un
docker logs api
```

```out auto
```

Работает: `{"status":"ok"}`, меню из трёх напитков, процесс идёт от пользователя `node`, в логе — строка запуска. Это первая версия «боевого» образа: он останется с нами до самого конца лабы и в сессии 5 станет ещё меньше.

### why
Здесь собрано всё, что ты узнала в этой сессии: exec-форма запуска, зависимости до кода (кэш), `.dockerignore`, не-root пользователь и воспроизводимая установка `npm ci`. Именно так выглядят правильные Dockerfile-ы для Node-проектов, и после этого шага ты можешь открыть чужой Dockerfile и понять каждую строку.

### deep Как ещё можно
- **Без контейнера:** если на Mac установлен Node (`brew install node@24`), `package-lock.json` создаётся командой `npm install --package-lock-only` прямо в папке.
- **`npm install` вместо `npm ci`:** допустимо при разработке, но в образах `npm ci` надёжнее — не меняет версии и падает, если `package.json` и lock расходятся.
- **Образ `node:24-slim`** вместо alpine — если пакеты с нативным кодом не собираются под musl (шаг 3.4).

### deep Если не получилось
- **`npm error Cannot read "package-lock.json"`** (при сборке) — lock-файла нет рядом с `Dockerfile`: сначала выполни шаг с `--package-lock-only`.
- **`EADDRINUSE` или `port is already allocated`** — на порту 3000 что-то уже слушает; выбери другой порт слева, например `-p 3001:3000`.
- **`curl: (7) Failed to connect`** — сервер ещё стартует (подожди секунду) или забыла `-p`; смотри `docker logs api`.
- **Контейнер сразу `Exited (1)`** — `docker logs api`: чаще всего опечатка в `server.js` или не установились зависимости.

### quiz
- Зачем в Dockerfile сначала копируются только `package.json` и `package-lock.json`?
- Чем `npm ci` отличается от `npm install` и почему он лучше для образа?
- Какой пользователь запускает процесс в контейнере и как ты это проверила?

### links
- https://docs.npmjs.com/cli/commands/npm-ci | npm ci | npm ci
- https://expressjs.com/ | Express | Express

## 4.6 entrypoint.sh и exec "$@" | short: Свой entrypoint | est: ~40 мин
### intro
**Слова шага:** *entrypoint-скрипт*, *`exec`*, *`"$@"`*, *`set -e`*, *PID 1*.

:::tip Если совсем просто
Скрипт-entrypoint — это «администратор на входе»: проверил билеты, повесил табличку и… **передал гостя** самому артисту. Слово `exec` означает «передать насовсем»: администратор уходит, артист остаётся главным. Если администратор не уходит, а просто стоит рядом, то «вежливое “заканчивай”» услышит он, а не артист.
:::

Иногда перед запуском приложения нужно что-то подготовить: проверить переменные, подождать базу, напечатать настройки. Для этого пишут **entrypoint-скрипт** — маленький shell-скрипт, который выполняет подготовку и в конце **запускает приложение**. Самое важное — как он запускает: `exec "$@"` (разберём ниже). Создадим скрипт и новый Dockerfile:

```bash run
cd ~/docker-lab/coffeeshop/api
cat > entrypoint.sh <<'EOF'
#!/bin/sh
set -e
echo "[entrypoint] CoffeeShop API, режим: ${APP_ENV:-dev}, порт: ${PORT:-3000}"
exec "$@"
EOF
cat > Dockerfile <<'EOF'
FROM node:24-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --chmod=755 entrypoint.sh ./
COPY server.js ./
USER node
EXPOSE 3000
ENTRYPOINT ["./entrypoint.sh"]
CMD ["node", "server.js"]
EOF
docker rm -f api
docker build -q -t coffee-api:2 .
docker run -d --name api -p 3000:3000 -e APP_ENV=prod coffee-api:2
sleep 2
docker logs api
docker exec api ps
```

### result
```out auto
```

Разбор скрипта: `#!/bin/sh` — какой интерпретатор запускать; **`set -e`** — остановиться при первой ошибке; `echo` — печатаем настройки (`${APP_ENV:-dev}` значит «значение `APP_ENV`, а если не задана — `dev`»); **`exec "$@"`** — запустить то, что пришло как аргументы. А пришли `CMD`-аргументы: `node server.js` (шаг 4.3: итоговая команда = `ENTRYPOINT` + `CMD`). **`exec`** *заменяет* процесс скрипта процессом `node`, и поэтому в списке процессов видно, что PID 1 — именно `node`, а скрипта уже нет.

Покажем, что будет **без `exec`**. Сделаем плохую версию скрипта: в конце просто `"$@"`:

```bash run
cd ~/docker-lab/coffeeshop/api
cat > entrypoint-bad.sh <<'EOF'
#!/bin/sh
set -e
echo "[entrypoint] запускаю без exec"
"$@"
EOF
sed 's#entrypoint.sh#entrypoint-bad.sh#g' Dockerfile > Dockerfile.bad
docker build -q -f Dockerfile.bad -t coffee-api:bad .
docker run -d --name api-bad -p 3001:3000 coffee-api:bad
sleep 2
docker exec api-bad ps
```

```out auto
```

Теперь PID 1 — `sh` (скрипт), а `node` — его ребёнок с другим номером. Проверим главное — остановку. Хороший контейнер и плохой, замерим время `stop`:

```bash run
time docker stop api
docker inspect --format 'хороший: код выхода {{.State.ExitCode}}' api
time docker stop api-bad
docker inspect --format 'плохой: код выхода {{.State.ExitCode}}' api-bad
```

```out auto
```

Хороший остановился мгновенно с кодом `0` (SIGTERM дошёл до `node`, тот закрылся). Плохой завис на 10 секунд и закончился кодом `137`: SIGTERM получил скрипт-PID 1, а у него нет обработчика, поэтому Docker дождался тайм-аута и убил всё SIGKILL. В продакшне это означает потерянные запросы и медленные обновления. Правило: **в конце entrypoint-скрипта всегда `exec "$@"`**. Уберём лишнее:

```bash run
docker rm -f api api-bad
docker rmi coffee-api:bad
```

```out auto
```

### why
`exec "$@"` — три слова, которые отличают «просто работает» от «работает и корректно останавливается». Эти же три слова — стандарт для всех официальных образов (посмотри `docker-entrypoint.sh` у `postgres` или `nginx`: у обоих в конце `exec "$@"`). Теперь, когда в логе контейнера пишут «убит по тайм-ауту, код 137», ты знаешь первое, что проверить.

### deep Команда по частям
`exec "$@"`: `exec` — «заменить текущий процесс этой командой»; `"$@"` — **все аргументы скрипта**, каждый как отдельное слово (в кавычках, чтобы пробелы внутри аргументов не ломались). В нашем случае аргументы — это `node` и `server.js` из `CMD`. Благодаря этому через `docker run образ node -v` скрипт запустит `node -v`, а через `docker run образ sh` — оболочку: entrypoint остаётся «на входе» всегда.

### deep Как ещё можно
- **Подготовка до запуска:** в скрипт можно добавить ожидание базы, создание папок, миграции — после них всё равно `exec "$@"`.
- **Запретить скрипту работать с пустыми переменными:** `set -eu` (`-u` — ошибка на необъявленной переменной).
- **Не писать свой скрипт:** для простого случая хватает `CMD ["node", "server.js"]`; скрипт нужен, когда нужна подготовка.
- **`tini`/`--init`:** флаг `docker run --init` ставит крошечный «менеджер процессов» как PID 1: он пробрасывает сигналы и убирает «зомби»-процессы.

### deep Если не получилось
- **`./entrypoint.sh: not found` или `no such file or directory`** — первая строка скрипта (`#!/bin/sh`) указывает интерпретатор, которого нет в образе, или у файла «виндовые» переводы строк (CRLF). Пересохрани с обычными переводами строк.
- **`permission denied`** — нет права на выполнение: `COPY --chmod=755` или `RUN chmod +x`.
- **Аргументы `CMD` не доходят** — в Dockerfile `ENTRYPOINT` в shell-форме; перепиши в exec-форму.

### quiz
- Что делает `exec "$@"` и почему без него `docker stop` занимает 10 секунд?
- Почему PID 1 в плохом контейнере — `sh`, а в хорошем — `node`?
- Откуда в `"$@"` берутся слова `node server.js`?

### links
- https://docs.docker.com/reference/dockerfile/#entrypoint | ENTRYPOINT | Dockerfile ENTRYPOINT
- https://github.com/krallin/tini | tini — менеджер PID 1 | tini

## 4.7 🔨 Сломать → починить: правка одной строки пересобирает всё | short: Порядок слоёв | est: ~35 мин
### intro
**Слова шага:** *порядок слоёв*, *кэш*, *`COPY . .`*, *время сборки*.

:::tip Если совсем просто
Ты исправила одну запятую в рецепте — а повар разобрал весь торт и испёк заново. Так бывает, когда «меняющееся» стоит в рецепте слишком высоко. Исправление: поменять порядок шагов.
:::

Воспроизведём самую частую причину медленных сборок: рецепт, в котором весь код копируется **до** установки зависимостей. Сделаем «наивный» Dockerfile:

```bash run
cd ~/docker-lab/coffeeshop/api
cat > Dockerfile.naive <<'EOF'
FROM node:24-alpine
WORKDIR /app
COPY . .
RUN npm ci --omit=dev
USER node
EXPOSE 3000
CMD ["node", "server.js"]
EOF
docker build -q -f Dockerfile.naive -t coffee-api:naive . > /dev/null
echo '// правка комментария' >> server.js
docker build --progress=plain -f Dockerfile.naive -t coffee-api:naive . 2>&1 | grep -E 'CACHED|npm ci|naming'
```

### result
```out auto
```

Мы дописали в `server.js` строку-комментарий — ничего не изменилось по смыслу. Но смотри: `COPY . .` пересобрался (изменился файл), а значит и `RUN npm ci --omit=dev` выполнился **заново** (в выводе он без `CACHED`) — Docker снова скачивал все пакеты, хотя `package.json` не менялся. На реальном проекте это минуты на каждую правку.

**Починка** — тот порядок, который у нас в рабочем Dockerfile (шаг 4.5): сначала копируются только файлы зависимостей, потом ставятся пакеты, потом копируется код. Проверим на правильном Dockerfile, сделав такую же правку:

```bash run
cd ~/docker-lab/coffeeshop/api
docker build -q -t coffee-api:3 . > /dev/null
echo '// ещё одна правка комментария' >> server.js
docker build --progress=plain -t coffee-api:3 . 2>&1 | grep -E 'CACHED|npm ci|naming'
```

```out auto
```

`RUN npm ci --omit=dev` теперь с пометкой `CACHED`: пересобралась только инструкция `COPY server.js` и всё ниже неё. Вместо минут — секунды. Уберём лишние образы и наши экспериментальные файлы:

```bash run
cd ~/docker-lab/coffeeshop/api
docker rmi coffee-api:naive coffee-api:3
rm -f Dockerfile.naive Dockerfile.bad entrypoint-bad.sh
ls
```

```out auto
```

### why
Порядок инструкций — это не вкус, а производительность. Эталонный порядок для любого проекта с зависимостями: **база → зависимости (манифест + установка) → код → запуск**. То, что меняется реже, выше; то, что чаще, ниже. Так работают сборки в CI и у разработчиков: пересобирается только то, что действительно поменялось.

### deep Если не получилось
- **`npm ci` в обоих случаях `CACHED`** — комментарий дописан не в тот файл или кэш уже был: сделай ещё одну правку `server.js`.
- **Оба раза `npm ci` выполняется** — в хорошем Dockerfile выше `npm ci` есть что-то, что меняется каждый раз (например, `COPY . .`): проверь порядок.
- **Нужно сбросить кэш целиком** — `docker build --no-cache`.

### quiz
- Почему при `COPY . .` до `npm ci` правка комментария в коде заставляет заново ставить пакеты?
- Какой порядок инструкций правильный и почему?
- Как по выводу сборки понять, что слой взят из кэша?

### outro
:::tip Приёмка сессии 4
- Ты читаешь любой Dockerfile: `FROM`, `WORKDIR`, `COPY`/`ADD`, `RUN`, `ENV`/`ARG`, `USER`, `HEALTHCHECK`, `ENTRYPOINT`/`CMD`.
- Ты пишешь `CMD` и `ENTRYPOINT` в exec-форме и объясняешь, почему.
- Образ `coffee-api` собран, запущен, отвечает на `/health` и `/menu`, работает от пользователя `node`.
- В `entrypoint.sh` стоит `exec "$@"`, и ты можешь показать разницу в `docker stop` (мгновенно, код 0) без `exec` (10 секунд, код 137).
- Пересборка после правки кода занимает секунды: `npm ci` берётся из кэша.
- Есть `.dockerignore`, и ты знаешь, зачем в нём `node_modules` и `.env`.
:::
