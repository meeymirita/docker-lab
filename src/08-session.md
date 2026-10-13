# Сессия 8 · Docker Compose, часть 1
dur: ~4 ч

## 8.1 YAML с нуля | short: YAML | est: ~30 мин
### intro
**Слова шага:** *YAML*, *отступ*, *список*, *словарь (map)*, *скаляр*, *комментарий*, *якорь*.

:::tip Если совсем просто
YAML — это **список дел с вложенностью**: что главное, что внутри него. Вложенность показывают **пробелами в начале строки** (как отступами в оглавлении). Один лишний или недостающий пробел — и смысл другой.
:::

```svg
<svg viewBox="0 0 640 250" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Compose: один файл вместо множества команд docker run" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m1-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m1-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><text x="150" y="20" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor" fill-opacity="1">Было: команды руками</text><rect x="15" y="32" width="270" height="30" rx="8" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-width="1.5"/><text x="150.0" y="52.0" text-anchor="middle" font-size="12" fill="currentColor">docker network create front</text><rect x="15" y="68" width="270" height="30" rx="8" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-width="1.5"/><text x="150.0" y="88.0" text-anchor="middle" font-size="12" fill="currentColor">docker volume create pgdata</text><rect x="15" y="104" width="270" height="30" rx="8" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-width="1.5"/><text x="150.0" y="124.0" text-anchor="middle" font-size="12" fill="currentColor">docker run -d --name db …</text><rect x="15" y="140" width="270" height="30" rx="8" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-width="1.5"/><text x="150.0" y="160.0" text-anchor="middle" font-size="12" fill="currentColor">docker run -d --name api …</text><rect x="15" y="176" width="270" height="30" rx="8" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-width="1.5"/><text x="150.0" y="196.0" text-anchor="middle" font-size="12" fill="currentColor">docker run -d --name web -p 8080:80 …</text><line x1="295" y1="125" x2="345" y2="125" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)"/><text x="320" y="115" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">один файл</text><rect x="355" y="20" width="270" height="210" rx="8" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="490" y="40" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor" fill-opacity="1">compose.yaml</text><text x="372" y="66" text-anchor="start" font-size="12" fill="currentColor" fill-opacity="1">services:</text><text x="372" y="90" text-anchor="start" font-size="12" fill="currentColor" fill-opacity="1">   db:  image, volumes, healthcheck</text><text x="372" y="114" text-anchor="start" font-size="12" fill="currentColor" fill-opacity="1">   api: build, depends_on</text><text x="372" y="138" text-anchor="start" font-size="12" fill="currentColor" fill-opacity="1">   web: build, ports</text><text x="372" y="162" text-anchor="start" font-size="12" fill="currentColor" fill-opacity="1">networks:  front, back</text><text x="372" y="186" text-anchor="start" font-size="12" fill="currentColor" fill-opacity="1">volumes:   pgdata</text><text x="490" y="245" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor" fill-opacity="1">docker compose up -d</text></svg>
```

Compose читает один файл **`compose.yaml`** на языке **YAML**. Всё, что в нём нужно знать:

- **Отступ — это смысл.** Вложенность задаётся пробелами (по два на уровень). **Табуляции нельзя.**
- **Словарь (map)** — пары `ключ: значение`. Значение может быть вложенным словарём.
- **Список** — строки, начинающиеся с `- `.
- **Строки** обычно пишут без кавычек; если внутри двоеточие, решётка или значение похоже на число/логическое — бери в кавычки (`"8080:80"`, `"yes"`).
- **Комментарий** — всё после `#`.

Два одинаковых по смыслу способа записать переменные окружения — словарь и список:

```bash run
mkdir -p ~/docker-lab/s08/yaml && cd ~/docker-lab/s08/yaml
cat > a.yaml <<'EOF'
services:
  app:
    image: alpine:3.22
    environment:
      GREETING: привет
      MODE: dev
    ports:
      - "8080:80"
EOF
cat > b.yaml <<'EOF'
services:
  app:
    image: alpine:3.22
    environment:
      - GREETING=привет
      - MODE=dev
    ports:
      - "8080:80"
EOF
docker compose -f a.yaml config > a.out
docker compose -f b.yaml config > b.out
diff a.out b.out && echo "Compose понял оба файла одинаково"
```

### result
```out auto
```

В `a.yaml` `environment` — **словарь** (`ключ: значение`), в `b.yaml` — **список** (`- КЛЮЧ=значение`). Compose привёл оба к одному виду, и `diff` не нашёл различий. Команда `docker compose config` — твой лучший друг: она показывает, **как Compose понял файл** (после подстановки переменных и нормализации). Теперь покажем, что бывает, если ошибиться с отступом. Нарочно сломаем файл: `image` сдвинут на лишний пробел:

```bash run
cd ~/docker-lab/s08/yaml
cat > broken.yaml <<'EOF'
services:
  app:
    image: alpine:3.22
     command: sleep 5
EOF
docker compose -f broken.yaml config
```

```out auto
```

Читай сообщение: оно указывает **строку и колонку** (`L4.C13` — строка 4, символ 13) и суть — «здесь не должно быть пары `ключ: значение`»; это следствие лишнего отступа в строке выше. Если сообщение непонятное — смотри строку **над** указанной: часто сломан отступ там. Ещё одна полезная возможность YAML — **якоря**: один раз описать блок и повторно вставить его (`&имя` — пометить, `*имя` — вставить). Compose использует их, чтобы не копировать настройки:

```bash run
cd ~/docker-lab/s08/yaml
cat > anchors.yaml <<'EOF'
x-common: &common
  restart: unless-stopped
  environment:
    TZ: Europe/Moscow

services:
  one:
    image: alpine:3.22
    <<: *common
  two:
    image: alpine:3.22
    <<: *common
EOF
docker compose -f anchors.yaml config
```

```out auto
```

Блок `x-common` (ключи на `x-` Compose игнорирует — это «свободное место» для заготовок) вставлен в оба сервиса через `<<: *common`: у `one` и у `two` есть и `restart`, и `TZ`. (Compose для удобства выводит сервисы и заготовку отсортированными по алфавиту.)

### why
Почти все «Compose не запускается» — это ошибки YAML: лишний пробел, табуляция, забытые кавычки. Привычка запускать `docker compose config` после каждой правки превращает загадочную ошибку в строку с номером — и половина проблем исчезает.

### deep Команда по частям
`docker compose -f a.yaml config > a.out`: `-f a.yaml` — какой файл читать (по умолчанию ищется `compose.yaml` в текущей папке); `config` — вывести итоговую конфигурацию; `> a.out` — сохранить вывод в файл. `diff a.out b.out && echo …` — `diff` сравнивает файлы; `&&` выполняет `echo`, только если различий нет.

### deep Как ещё можно
- **Проверка без вывода:** `docker compose config -q` — молчит, если файл верный; ошибка при проблеме.
- **Редакторы:** VS Code с расширениями «YAML» и «Docker» подсвечивает ошибки отступов сразу.
- **Многострочный текст:** `command: |` и дальше строки с отступом — строки сохраняются как есть.

### deep Если не получилось
- **`found character that cannot start any token`** — в файле табуляция вместо пробелов.
- **`did not find expected key` / `mapping values are not allowed here`** — неправильный отступ или двоеточие внутри значения без кавычек.
- **Значение «не то»** — `no`, `yes`, `on` YAML может прочитать как логические значения; пиши в кавычках.

### quiz
- Чем в YAML отличается список от словаря и как их отличить глазами?
- Для чего нужна команда `docker compose config`?
- Почему в YAML нельзя использовать табуляции?

### links
- https://docs.docker.com/reference/compose-file/ | справочник Compose-файла | Compose file reference
- https://yaml.org/spec/1.2.2/ | спецификация YAML | YAML spec

## 8.2 Первый compose.yaml: от docker run к файлу | short: Первый compose.yaml | est: ~40 мин
### intro
**Слова шага:** *Compose*, *сервис*, *проект*, *`services`*, *`networks`*, *`volumes`*, *`docker compose up`*.

:::tip Если совсем просто
Раньше ты каждый раз диктовала повару заказ по частям: «возьми это, поставь туда, включи то». Compose — **меню на листе**: записала один раз — и «`docker compose up`» запускает всё сразу в правильном порядке.
:::

Мы запускали контейнеры командами `docker run` с кучей флагов. **Docker Compose** позволяет описать **всё приложение** одним файлом `compose.yaml` и управлять им парой команд. Основные понятия: **сервис** (`service`) — «роль» приложения (web, api, db), описание того, как запускать контейнер; **проект** (`project`) — группа сервисов из одного файла (имя по умолчанию — имя папки); у проекта есть свои сети и тома.

Начнём с простого. Команда `docker run -d --name web -p 8090:80 nginx:1.30-alpine` превращается в файл:

```bash run
mkdir -p ~/docker-lab/s08/first && cd ~/docker-lab/s08/first
cat > compose.yaml <<'EOF'
services:
  web:
    image: nginx:1.30-alpine
    ports:
      - "8090:80"
EOF
docker compose up -d
sleep 2
docker compose ps
curl -s -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:8090
```

### result
```out auto
```

Что произошло: Compose прочитал `compose.yaml`, создал сеть проекта (`first_default`), запустил контейнер сервиса `web` с именем `first-web-1` (формат: `проект-сервис-номер`) и опубликовал порт. `docker compose ps` показывает контейнеры **только этого проекта**. Остановить и удалить всё созданное — `docker compose down`:

```bash run
cd ~/docker-lab/s08/first
docker compose down
docker ps -a --format 'table {{.Names}}'
docker network ls --format '{{.Name}}'
```

```out auto
```

`down` удалил контейнер **и сеть проекта** (имена `first-web-1` и `first_default` исчезли). Теперь полный пример для нашей базы: ключи Compose почти один-в-один повторяют флаги `docker run`:

| Флаг `docker run` | Ключ в `compose.yaml` |
|---|---|
| `--name x` | имя сервиса (`services: x:`), `container_name:` — редко |
| образ в конце команды | `image:` |
| `-p 8080:80` | `ports: ["8080:80"]` |
| `-e KEY=val` | `environment:` |
| `-v том:путь` | `volumes:` |
| `--network имя` | `networks:` |
| `--restart` | `restart:` |
| `--health-cmd` | `healthcheck:` |
| команда после образа | `command:` |
| сборка из Dockerfile | `build:` |

Запишем базу из шага 7.6 как сервис. Тома и сети объявляются отдельными секциями верхнего уровня:

```bash run
mkdir -p ~/docker-lab/s08/db && cd ~/docker-lab/s08/db
cat > compose.yaml <<'EOF'
services:
  db:
    image: postgres:18
    environment:
      POSTGRES_USER: coffee
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: coffee
    volumes:
      - pgdata:/var/lib/postgresql

volumes:
  pgdata:
EOF
docker compose up -d
sleep 8
docker compose exec db psql -U coffee -d coffee -c "SELECT current_database(), current_user;"
docker compose ps --format 'table {{.Name}}\t{{.Service}}\t{{.Status}}'
docker volume ls --format '{{.Name}}' | grep db_pgdata
docker compose down
```

```out auto
```

Том проекта получил имя `<проект>_pgdata` (`db_pgdata`, потому что папка называется `db`) — Compose добавляет префикс проекта ко всему, что создаёт, чтобы разные проекты не мешали друг другу. Обрати внимание: `docker compose down` **не удалил том** — данные сохраняются (для удаления нужен флаг `-v`, шаг 8.3).

### why
Это та же работа, что делали команды `docker run`, но **описанная один раз и хранимая в репозитории**: новый разработчик клонирует проект, пишет `docker compose up` — и получает точно такое же окружение. Если ты умеешь запускать контейнеры вручную (а ты умеешь), Compose — просто удобный способ записать эти знания.

### deep Команда по частям
`docker compose up -d`: `up` — создать (если нет) и запустить всё из файла; `-d` — в фоне. `docker compose exec db psql …` — как `docker exec`, только по **имени сервиса** (`db`), не по имени контейнера. `ps --format 'table …'` — тот же шаблон, что у `docker ps`. Имя проекта задаётся ключом `name:` в файле, флагом `-p` или переменной `COMPOSE_PROJECT_NAME`.

### deep Как ещё можно
- **Имя файла:** кроме `compose.yaml` Compose понимает `compose.yml`, `docker-compose.yaml` (старое имя); другой файл — `-f имя`.
- **Закрепить имя проекта:** первой строкой `name: coffeeshop` — тогда имена не зависят от названия папки.
- **`version:`** в начале файла — устаревший ключ; в новых файлах его не пишут.

### deep Если не получилось
- **`no configuration file provided: not found`** — запускаешь не из папки с `compose.yaml`.
- **`port is already allocated`** — порт занят другим контейнером (в том числе из другого проекта).
- **`services.db.volumes must be a list`** — в `volumes` у сервиса должен быть список (`- …`), а не словарь.

### quiz
- Что такое сервис и проект в Compose?
- Какой флаг `docker run` соответствует ключу `environment`?
- Почему `docker compose down` не удаляет том и как именованный том получает имя?

### links
- https://docs.docker.com/compose/intro/compose-application-model/ | модель приложения Compose | Compose application model
- https://docs.docker.com/reference/compose-file/services/ | ключи сервиса | Compose services

## 8.3 Команды Compose на каждый день | short: Команды Compose | est: ~35 мин
### intro
**Слова шага:** *`up`*, *`down`*, *`ps`*, *`logs`*, *`exec`*, *`build`*, *`config`*, *`-p`*, *`down -v`*.

:::tip Если совсем просто
Пульт от всей кофейни: «включить всё» (`up`), «выключить всё» (`down`), «что сейчас работает» (`ps`), «послушать, что говорят» (`logs`), «зайти и сказать пару слов» (`exec`). Кнопок немного — зато они управляют всем сразу.
:::

Подготовим проект из двух сервисов — веб-сервер и «часы», которые каждую секунду пишут слово в лог (`command` задаёт, что запустить вместо команды по умолчанию):

```bash run
mkdir -p ~/docker-lab/s08/cmds && cd ~/docker-lab/s08/cmds
cat > compose.yaml <<'EOF'
services:
  web:
    image: nginx:1.30-alpine
    ports:
      - "8091:80"
  ticker:
    image: alpine:3.22
    command: sh -c 'while true; do echo tick; sleep 1; done'
EOF
docker compose up -d
sleep 3
docker compose ps
```

### result
```out auto
```

Основные команды — работают сразу со всеми сервисами проекта или с одним:

| Команда | Что делает |
|---|---|
| `docker compose up -d` | создать и запустить всё (если уже есть — перезапустить изменившееся) |
| `docker compose down` | остановить и **удалить** контейнеры и сети проекта |
| `docker compose down -v` | то же, **и тома** проекта (осторожно: данные!) |
| `docker compose ps` / `ps -a` | состояние сервисов |
| `docker compose logs [сервис]` | логи (`-f` следить, `--tail N`, `--since`) |
| `docker compose exec сервис команда` | выполнить команду в работающем контейнере |
| `docker compose run --rm сервис команда` | запустить **новый** одноразовый контейнер сервиса |
| `docker compose stop` / `start` / `restart` | остановить / запустить / перезапустить без удаления |
| `docker compose build` / `up --build` | пересобрать образы сервисов с `build:` |
| `docker compose pull` | скачать свежие образы |
| `docker compose config` | показать итоговую конфигурацию |
| `docker compose ls` | список проектов на машине |

Попробуем часть из них:

```bash run
cd ~/docker-lab/s08/cmds
docker compose logs --tail 3 ticker
docker compose exec web nginx -v
docker compose stop ticker
docker compose ps -a --format 'table {{.Service}}\t{{.Status}}'
docker compose start ticker
docker compose run --rm ticker echo "одноразовый контейнер сервиса ticker"
docker compose ls
```

```out auto
```

`logs --tail 3 ticker` — три последние строки одного сервиса. `exec web …` — по имени сервиса. `stop` остановил `ticker`: в `ps -a` он `Exited (137)` — как `sleeper` в шаге 2.6: `sh` в роли PID 1 не реагирует на SIGTERM, и Compose через 10 секунд убил его сигналом SIGKILL. `start` вернул сервис. `run --rm` создал **отдельный** контейнер (не тот, что в проекте), выполнил команду и удалился. `docker compose ls` показывает проекты, найденные Compose.

**Имя проекта и `-p`.** Один и тот же `compose.yaml` можно запустить дважды под разными именами проекта — получатся две независимые копии со своими сетями и томами (порты придётся поменять):

```bash run
cd ~/docker-lab/s08/cmds
docker compose -p copy2 up -d ticker
docker compose ls
docker ps --format 'table {{.Names}}\t{{.Status}}'
docker compose -p copy2 down
```

```out auto
```

Видны два проекта: `cmds` и `copy2` (у каждого свои контейнеры: `cmds-web-1`, `cmds-ticker-1`, `copy2-ticker-1`). Наконец, главное различие **`down` и `down -v`**: первое сохраняет тома (данные), второе стирает их:

```bash run
cd ~/docker-lab/s08/cmds
docker compose down
docker ps -a --format 'table {{.Names}}'
```

```out auto
```

### why
Команд Compose мало, а ежедневно хватает пяти: `up -d`, `ps`, `logs`, `exec`, `down`. Остальные — по необходимости. И запомни главное предупреждение: `down -v` стирает тома, то есть **данные базы**. Перед ним спроси себя: «А бэкап есть?» (шаг 7.6).

### deep Команда по частям
`docker compose -p copy2 up -d ticker`: `-p copy2` — имя проекта; `up -d ticker` — запустить **только** сервис `ticker` (и всё, от чего он зависит). Любую команду Compose можно ограничить одним сервисом, написав его имя в конце: `docker compose restart web`.

### deep Как ещё можно
- **Следить за несколькими:** `docker compose logs -f web ticker`.
- **Ресурсы:** `docker compose top` — процессы; `docker compose images` — образы проекта.
- **Пересоздать контейнер:** `docker compose up -d --force-recreate web`.
- **Убрать «осиротевшие» контейнеры:** `docker compose up -d --remove-orphans` (если сервис убрали из файла).

### deep Если не получилось
- **Команда `docker compose …` не находит сервис** — имя сервиса из файла, а не имя контейнера; смотри `docker compose config --services`.
- **`orphan containers`** — в проекте остались контейнеры сервисов, которых нет в файле; `--remove-orphans`.
- **Забыла `-d` и терминал «завис»** — это `up` без фона: останавливай [[Ctrl]]+[[C]].

### quiz
- В чём разница между `docker compose exec` и `docker compose run`?
- Что делает `docker compose down -v` и чем опасно?
- Как запустить один и тот же файл два раза независимо?

### links
- https://docs.docker.com/reference/cli/docker/compose/ | команды docker compose | docker compose

## 8.4 Переменные: environment, env_file, .env | short: Переменные в Compose | est: ~40 мин
### intro
**Слова шага:** *`environment`*, *`env_file`*, *файл `.env`*, *интерполяция `${VAR}`*, *`${VAR:-по_умолчанию}`*, *`${VAR:?ошибка}`*, *приоритет*.

:::tip Если совсем просто
Записки на двери бывают из разных мест: из **ящика с записками** (`.env`), из **конкретной папки** (`env_file`), вписанные **от руки в карточку сервиса** (`environment`) или **выкрикнутые прямо сейчас** (в терминале). Если записок несколько, побеждает та, что **ближе к делу и громче**.
:::

Настройки (порты, пароли, режимы) не должны быть вписаны в `compose.yaml` — они разные на твоём Mac и на сервере. Поэтому у Compose несколько способов подставить переменные. Различай два понятия:

- **Интерполяция** — подстановка `${ИМЯ}` **в самом `compose.yaml`** (до запуска): `image: postgres:${PG_VERSION}`.
- **Переменные контейнера** — то, что процесс внутри увидит как `env` (ключи `environment` и `env_file`).

Формы интерполяции: `${VAR}` — подставить значение; `${VAR:-значение}` — если не задана или пуста, взять значение по умолчанию; `${VAR:?сообщение}` — если не задана, **остановиться** с ошибкой. Источники значений для интерполяции: **переменные оболочки**, затем файл **`.env`** рядом с `compose.yaml`. Попробуем:

```bash run
mkdir -p ~/docker-lab/s08/vars && cd ~/docker-lab/s08/vars
printf 'GREETING=привет из .env\nPORT=8095\n' > .env
printf 'FROM_FILE=значение из env_file\nFIXED=из файла\n' > app.env
cat > compose.yaml <<'EOF'
services:
  show:
    image: alpine:3.22
    env_file:
      - app.env
    environment:
      GREETING: ${GREETING:-hello}
      PORT_FROM_ENV: ${PORT}
      FIXED: из environment
      NEEDED: ${NEEDED:-не задана}
    command: sh -c 'env | grep -E "^(GREETING|PORT_FROM_ENV|FIXED|FROM_FILE|NEEDED)=" | sort'
EOF
docker compose run --rm show
```

### result
```out auto
```

Разбор по строкам: `GREETING` взят из `.env` (`привет из .env`), потому что в оболочке такой переменной нет; `PORT_FROM_ENV` — тоже из `.env`; `FROM_FILE` пришёл из `env_file` (`app.env`); `NEEDED` не задана нигде — сработало значение по умолчанию. А `FIXED` задан **и в `env_file`, и в `environment`** — победило значение из `environment` (`из environment`): явная запись в карточке сервиса сильнее общего файла. Теперь **переменная оболочки** — она сильнее `.env`:

```bash run
cd ~/docker-lab/s08/vars
GREETING="из оболочки" docker compose run --rm show | grep -E 'GREETING'
echo "--- как это видит config:"
GREETING="из оболочки" docker compose config | grep 'GREETING:'
```

```out auto
```

Порядок для интерполяции — **от сильного к слабому**: переменная в оболочке → файл `.env` → значение после `:-` в самом файле. А `${VAR:?…}` помогает заранее сломаться, если обязательное значение забыто. Проверим:

```bash run
cd ~/docker-lab/s08/vars
cat > must.yaml <<'EOF'
services:
  db:
    image: postgres:18
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD:?Задай DB_PASSWORD в .env}
EOF
docker compose -f must.yaml config
echo "--- с переменной:"
DB_PASSWORD=secret docker compose -f must.yaml config | grep POSTGRES
```

```out auto
```

Без `DB_PASSWORD` Compose остановился с понятным сообщением (наша фраза после `?`); с переменной — всё в порядке. Паролей и ключей в самом `compose.yaml` быть не должно: их кладут в `.env` (в `.gitignore`!) или передают из окружения.

:::trap Секреты и git
Файл `.env` с настоящими паролями **не коммитят**: добавь его в `.gitignore`, а в репозитории держи `.env.example` с пустыми или тестовыми значениями — как шаблон.
:::

### why
Конфигурация отдельно от кода — один из главных принципов. Один и тот же `compose.yaml` у тебя запускается с портом 8080 и простым паролем, а на сервере — с другими значениями из другого `.env`. Привычка писать `${VAR:-по_умолчанию}` для необязательного и `${VAR:?…}` для обязательного делает файл самодокументированным.

### deep Команда по частям
`GREETING="из оболочки" docker compose run --rm show`: запись `ИМЯ=значение команда` задаёт переменную **только для этой команды**. `docker compose run --rm show` — запустить одноразовый контейнер сервиса `show` и удалить после выхода. `env | grep -E "^(A|B)="` — вывести переменные окружения, оставив нужные; `sort` — упорядочить.

### deep Как ещё можно
- **Другой файл вместо `.env`:** `docker compose --env-file prod.env up -d`.
- **Несколько `env_file`:** список — последние перекрывают предыдущие.
- **Переменная из оболочки без значения:** `environment: [MODE]` — берёт значение `MODE` из окружения оболочки.
- **Не путать:** `.env` управляет интерполяцией в `compose.yaml`; в контейнер его содержимое попадает, только если ты явно указала `env_file` или `environment`.

### deep Если не получилось
- **Переменная пустая в контейнере** — она есть в `.env`, но не перечислена в `environment`/`env_file`; в контейнер попадает только то, что указано.
- **`variable is not set. Defaulting to a blank string`** — Compose предупреждает: `${VAR}` нигде не задана.
- **Значение с `#` обрезано** — в `.env` решётка начинает комментарий; бери значение в кавычки.

### quiz
- Чем интерполяция `${VAR}` отличается от `environment` и `env_file`?
- Что делают `${VAR:-x}` и `${VAR:?msg}`?
- Что победит, если переменная задана и в `.env`, и в оболочке; и если в `environment` и в `env_file`?

### links
- https://docs.docker.com/compose/how-tos/environment-variables/ | переменные в Compose | Environment variables
- https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/ | интерполяция | Interpolation

## 8.5 depends_on и healthcheck: «запущен» ≠ «готов» | short: depends_on и healthcheck | est: ~40 мин
### intro
**Слова шага:** *`depends_on`*, *`healthcheck`*, *`condition: service_healthy`*, *`pg_isready`*, *готовность сервиса*.

:::tip Если совсем просто
Повар включил плиту — но она ещё **греется**. «Плита включена» и «на плите можно жарить» — разные вещи. Помощнику нельзя говорить «жарь!», пока лампочка «готово» не загорится. Здоровье сервиса (`healthcheck`) — и есть такая лампочка.
:::

В шаге 4.2 мы видели `HEALTHCHECK`: команда, которую Docker периодически запускает и по результату помечает контейнер `healthy`. В Compose это ключ **`healthcheck`**. А **`depends_on`** задаёт порядок запуска: сервис `api` стартует после `db`. Но есть тонкость: по умолчанию `depends_on` ждёт только **запуска** контейнера, а не его **готовности**. PostgreSQL после старта ещё секунд 5–10 инициализируется и отвечать на запросы не готов. Покажем на примере. «Клиент» просто спрашивает базу `pg_isready` («готова ли?»):

```bash run
mkdir -p ~/docker-lab/s08/dep && cd ~/docker-lab/s08/dep
cat > nowait.yaml <<'EOF'
services:
  db:
    image: postgres:18
    environment:
      POSTGRES_PASSWORD: secret
  client:
    image: postgres:18
    depends_on:
      - db
    command: pg_isready -h db -U postgres
EOF
docker compose -f nowait.yaml up --abort-on-container-exit --no-log-prefix client 2>&1 | grep -E 'pg_isready|accepting|no response|rejecting' | head -3
docker compose -f nowait.yaml down -v > /dev/null 2>&1
```

### result
```out auto
```

`depends_on: [db]` дождался **запуска** контейнера `db`, и клиент сразу спросил — база ещё не готова (`no response` или `rejecting connections`). Приложение, которое стартует и сразу идёт в базу, в такой ситуации падает. Исправим двумя изменениями: у `db` описываем **`healthcheck`** — как узнать, что база готова; у клиента пишем `depends_on` с условием **`service_healthy`**:

```bash run
cd ~/docker-lab/s08/dep
cat > wait.yaml <<'EOF'
services:
  db:
    image: postgres:18
    environment:
      POSTGRES_USER: coffee
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: coffee
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 2s
      timeout: 3s
      retries: 15
  client:
    image: postgres:18
    depends_on:
      db:
        condition: service_healthy
    command: pg_isready -h db -U coffee -d coffee
EOF
docker compose -f wait.yaml up --abort-on-container-exit --no-log-prefix client 2>&1 | grep -E 'accepting|no response|rejecting' | head -3
docker compose -f wait.yaml down -v > /dev/null 2>&1
```

```out auto
```

Теперь Compose сначала запустил `db`, **ждал, пока `healthcheck` станет `healthy`**, и только потом запустил `client`, которого встретил ответ `accepting connections`. Разберём `healthcheck`: **`test`** — команда проверки (код `0` — здорово; форма `["CMD-SHELL", "…"]` запускает её через оболочку); **`interval`** — как часто проверять; **`timeout`** — сколько ждать ответа; **`retries`** — сколько неудач подряд признают контейнер `unhealthy`. В `test` стоят **двойные доллары** (`$${POSTGRES_USER}`): Compose сам подставляет переменные с `$`, а чтобы подстановку сделала оболочка **внутри контейнера**, знак `$` удваивают.

### why
Это одна из самых важных идей Compose: **порядок запуска — это не готовность**. Без `healthcheck` и `condition: service_healthy` приложение полагается на удачу («база успеет раньше»), а на медленной машине это не сработает. С ними запуск **детерминированный**: каждый ждёт именно тех, от кого зависит.

### deep Команда по частям
`docker compose -f nowait.yaml up --abort-on-container-exit --no-log-prefix client`: `--abort-on-container-exit` — остановить всё, когда любой контейнер завершился (нам нужен только ответ клиента); `--no-log-prefix` — не добавлять имя сервиса к строкам лога; в конце — запустить только `client` и то, что он требует. Вывод пропущен через `grep`, чтобы оставить интересные строки.

### deep Как ещё можно
- **Другие условия:** `service_started` (по умолчанию), `service_healthy`, `service_completed_successfully` (для одноразовых задач, например миграций).
- **Первая проверка не сразу:** `start_period: 10s` — в течение этого времени неудачи не считаются.
- **Проверка веб-сервиса:** `test: ["CMD", "wget", "-qO-", "http://localhost:3000/health"]` (в образе должен быть `wget`) или команда на самом языке приложения (шаг 8.6).
- **Приложение должно уметь и само повторять подключение** — на случай, если база перезапустилась позже.

### deep Если не получилось
- **`dependency failed to start: container … is unhealthy`** — `healthcheck` не стал `healthy` за `retries × interval`; смотри `docker compose logs db` и проверь команду `test` вручную: `docker compose exec db pg_isready …`.
- **`$POSTGRES_USER` не подставился** — написала один `$` вместо двух: Compose подставил пустое значение до запуска.
- **Ждёт слишком долго** — увеличь `retries` или `interval`; для первого запуска PostgreSQL нужно 5–15 секунд.

### quiz
- Чем «контейнер запущен» отличается от «сервис готов» и как Compose узнаёт второе?
- Что делает `condition: service_healthy`?
- Зачем в `healthcheck.test` пишут `$$` вместо `$`?

### links
- https://docs.docker.com/compose/how-tos/startup-order/ | порядок запуска | Control startup order
- https://docs.docker.com/reference/compose-file/services/#healthcheck | healthcheck | healthcheck

## 8.6 Запускаем полный CoffeeShop | short: Полный CoffeeShop | est: ~60 мин
### intro
**Слова шага:** *стек*, *`build:`*, *`depends_on`*, *Adminer*, *`pg`*, *`docker compose up --build`*.

:::tip Если совсем просто
Теперь собираем всю кофейню: **вывеска** (сайт), **администратор** (API), **сейф** (база) и **окошко для проверяющего** (Adminer — картинки базы). Всё описываем в одном листе и включаем одной кнопкой.
:::

Объединим всё, что мы сделали: API, сайт, база с томом и начальными данными, Adminer — удобный веб-интерфейс к базе. Сначала научим API работать с настоящей базой (до сих пор меню было вшито в код). Добавим библиотеку `pg` и перепишем `server.js`: меню берётся из таблицы `menu`, заказы пишутся в таблицу `orders`. При старте API проверяет связь с базой и **падает с понятным сообщением, если её нет** (так мы заметим проблему сразу):

```bash run
cd ~/docker-lab/coffeeshop/api
cat > package.json <<'EOF'
{
  "name": "coffeeshop-api",
  "version": "1.1.0",
  "type": "module",
  "private": true,
  "scripts": { "start": "node server.js" },
  "dependencies": { "express": "^5.1.0", "pg": "^8.13.0" }
}
EOF
cat > server.js <<'EOF'
import express from 'express'
import pg from 'pg'

const app = express()
app.use(express.json())
const port = process.env.PORT || 3000

const pool = new pg.Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  user: process.env.DB_USER || 'coffee',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'coffee',
})

app.get('/health', (req, res) => res.json({ status: 'ok' }))

app.get('/menu', async (req, res) => {
  const { rows } = await pool.query('SELECT id, name, price FROM menu ORDER BY id')
  res.json(rows)
})

app.post('/orders', async (req, res) => {
  const { rows } = await pool.query(
    'INSERT INTO orders (menu_id) VALUES ($1) RETURNING id, menu_id, created_at',
    [req.body.menu_id],
  )
  res.status(201).json(rows[0])
})

app.get('/orders', async (req, res) => {
  const { rows } = await pool.query(
    'SELECT o.id, m.name, m.price FROM orders o JOIN menu m ON m.id = o.menu_id ORDER BY o.id',
  )
  res.json(rows)
})

try {
  await pool.query('SELECT 1')
  console.log('база доступна')
} catch (e) {
  console.error('не удалось подключиться к базе:', e.message)
  process.exit(1)
}

const server = app.listen(port, () => console.log(`CoffeeShop API слушает порт ${port}`))

process.on('SIGTERM', () => {
  console.log('получен SIGTERM, закрываюсь')
  server.close(() => pool.end().then(() => process.exit(0)))
})
EOF
docker run --rm -v "$PWD":/app -w /app node:24-alpine npm install --package-lock-only --no-fund --no-audit --loglevel=error 2>&1 | grep -v notice
grep -c '"node_modules/pg"' package-lock.json
```

### result
```out auto
```

(Число `1` — пакет `pg` появился в `package-lock.json`; строки про «новую версию npm» мы отфильтровали.) Теперь обновим начальный SQL: к таблице `menu` добавим `orders`. И подготовим `.env` с настройками (пароль — **только здесь**), и `.dockerignore`/`.gitignore`-подобный файл для секретов:

```bash run
cd ~/docker-lab/coffeeshop
cat > db/init.sql <<'EOF'
CREATE TABLE menu (
  id    serial PRIMARY KEY,
  name  text NOT NULL,
  price integer NOT NULL
);

CREATE TABLE orders (
  id         serial PRIMARY KEY,
  menu_id    integer NOT NULL REFERENCES menu(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO menu (name, price) VALUES
  ('Эспрессо', 150),
  ('Капучино', 220),
  ('Латте', 250);
EOF
cat > .env <<'EOF'
DB_USER=coffee
DB_PASSWORD=secret
DB_NAME=coffee
WEB_PORT=8080
EOF
printf '.env\n' > .gitignore
ls -a
```

```out auto
```

Теперь сам `compose.yaml` — он собирает всё из предыдущих сессий: образы собираются из `build:`, у базы том и `healthcheck`, API ждёт базу, сайт ждёт API, у сервисов разные сети (шаг 6.6). Адрес `healthcheck` API — маленькая команда на самом Node (в distroless нет `wget`, шаг 5.2):

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

  adminer:
    image: adminer:5
    ports:
      - "127.0.0.1:8081:8080"
    depends_on:
      db:
        condition: service_healthy
    networks: [back]

networks:
  front:
  back:

volumes:
  pgdata:
EOF
docker compose config -q && echo "compose.yaml корректен"
docker compose up -d --build 2>&1 | tail -12
```

```out auto
```

Compose собрал образы `api` и `web`, создал две сети и том, запустил сервисы **в порядке зависимостей**: сначала `db`, дождался `healthy`, потом `api`, дождался его `healthy`, потом `web`. Посмотрим на результат:

```bash run
cd ~/docker-lab/coffeeshop
docker compose ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
```

```out auto
```

Порты опубликованы только у `web` (`8080`) и у `adminer` (только на `127.0.0.1:8081`, шаг 6.2); `db` и `api` снаружи недоступны. Проверим, что всё работает цепочкой «браузер → сайт → API → база». Сделаем два заказа и посмотрим список:

```bash run
cd ~/docker-lab/coffeeshop
curl -s -w '\n' http://localhost:8080/api/menu
curl -s -w '\n' -X POST -H 'Content-Type: application/json' -d '{"menu_id": 2}' http://localhost:8080/api/orders
curl -s -w '\n' -X POST -H 'Content-Type: application/json' -d '{"menu_id": 3}' http://localhost:8080/api/orders
curl -s -w '\n' http://localhost:8080/api/orders
docker compose exec adminer sh -c 'wget -qO- http://localhost:8080 | grep -o "<title>[^<]*"'
```

```out auto
```

Меню теперь приходит **из базы**, заказы записываются в таблицу, Adminer отвечает (последняя команда достаёт заголовок его страницы входа; в браузере: `http://localhost:8081`, система — PostgreSQL, сервер — `db`, пользователь `coffee`, пароль из `.env`, база `coffee`). И главное — проверка «данные живут дольше контейнеров»: остановим и удалим все контейнеры, поднимем снова и посмотрим заказы:

```bash run
cd ~/docker-lab/coffeeshop
docker compose down
docker compose up -d
sleep 10
docker compose ps --format 'table {{.Service}}\t{{.Status}}'
curl -s -w '\n' http://localhost:8080/api/orders
```

```out auto
```

Заказы на месте: контейнеры новые, а данные — в томе `coffeeshop_pgdata`. А вот `docker compose down -v` стёр бы том, и база начала бы с нуля (с `init.sql`). Посмотрим логи API — в них видна последовательность старта:

```bash run
cd ~/docker-lab/coffeeshop
docker compose logs api
```

```out auto
```

### why
Это главный результат первых восьми сессий: **весь стек CoffeeShop поднимается одной командой** и состоит из того, что ты разобрала по отдельности — образы (3–5), сети (6), тома (7), переменные и готовность (8). Если сломается — ты знаешь, в каком из слоёв искать.

### deep Команда по частям
`healthcheck.test: ["CMD", "/nodejs/bin/node", "-e", "fetch(…)…"]`: форма `CMD` — запуск без оболочки (в distroless её нет); `node -e "код"` — выполнить JavaScript; `fetch('http://localhost:3000/health')` — запросить свой же адрес; `process.exit(0 или 1)` — код выхода для Docker. В `ports` строка `"${WEB_PORT:-8080}:80"` берёт порт из `.env` или 8080 по умолчанию. `docker compose up -d --build` — пересобрать образы и запустить.

### deep Как ещё можно
- **Один сервис:** `docker compose up -d --build api` пересоберёт и перезапустит только API.
- **Посмотреть заказы напрямую:** `docker compose exec db psql -U coffee -d coffee -c "SELECT * FROM orders;"`.
- **Меню в браузере:** открой `http://localhost:8080` — страница из шага 5.6 загрузит меню из API (если скрипт сайта пересобран: `docker compose up -d --build web`).
- **Остановить без потери данных:** `docker compose down`; полностью очистить: `docker compose down -v`.

### deep Если не получилось
- **`unhealthy` у `db`** — смотри `docker compose logs db`; частые причины: неверный путь тома (шаг 7.7) или пароль не задан (`.env`).
- **`api` падает `не удалось подключиться к базе`** — проверь `DB_HOST: db` (имя сервиса), пароль в `.env` и что `db` в той же сети `back`.
- **`502` на `/api/…`** — `api` не запущен или ещё стартует: `docker compose ps`, `docker compose logs api`.
- **`variable DB_PASSWORD is required`** — в папке нет `.env` (запускай из `~/docker-lab/coffeeshop`).

### quiz
- В каком порядке Compose запустит сервисы и по чему он понимает, что можно идти дальше?
- Какие порты стека доступны с твоего Mac и почему только они?
- Что произойдёт с заказами после `docker compose down` и после `docker compose down -v`?

### links
- https://docs.docker.com/compose/gettingstarted/ | начало работы с Compose | Get started with Compose
- https://hub.docker.com/_/adminer | образ Adminer | adminer

## 8.7 🔨 Сломать → починить: приложение стартует раньше БД | short: Старт раньше базы | est: ~40 мин
### intro
**Слова шага:** *гонка запуска*, *`ECONNREFUSED`*, *`depends_on` без условия*, *`restart`*, *диагностика через `ps -a` и `logs`*.

:::tip Если совсем просто
Плита включена, но ещё холодная. Помощник сразу кричит «жарь!» — и у него ничего не получается. Он уходит обиженным. Лечение уже знаем: подождать, пока загорится лампочка «готово».
:::

Воспроизведём самую частую проблему Compose. Возьмём стек без ожидания готовности: у `api` будет простой `depends_on: [db]` (только «запущен»), как в шаге 8.5. Запустим его в проекте `broken`, чтобы не мешать основному:

```bash run
cd ~/docker-lab/coffeeshop
cat > compose.broken.yaml <<'EOF'
name: broken

services:
  db:
    image: postgres:18
    environment:
      POSTGRES_USER: coffee
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: coffee
    volumes:
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
  api:
    build: ./api
    environment:
      DB_HOST: db
      DB_PASSWORD: secret
    depends_on:
      - db
EOF
docker compose -p broken -f compose.broken.yaml up -d 2>&1 | tail -4
sleep 4
docker compose -p broken -f compose.broken.yaml ps -a --format 'table {{.Service}}\t{{.Status}}'
```

### result
```out auto
```

Сервис `api` в состоянии `Exited (1)` — упал сразу после старта. Диагностика та же, что в шаге 2.7: **сначала `ps -a` (в каком состоянии и с каким кодом), потом `logs`**:

```bash run
cd ~/docker-lab/coffeeshop
docker compose -p broken -f compose.broken.yaml logs api
```

```out auto
```

`не удалось подключиться к базе: connect ECONNREFUSED …:5432` — соединение **отклонено**: API нашёл адрес `db` (контейнер уже запущен), но порт 5432 ещё никто не слушает — PostgreSQL пока инициализирует данные. Это классическая гонка. Три способа лечения, от слабого к сильному:

1. **`restart: on-failure`** — если сервис упал, Compose перезапустит его; рано или поздно база будет готова. Простое, но работает «с попытками».
2. **Приложение повторяет подключение** само (цикл с паузами) — устойчиво и к перезапуску базы позже.
3. **`healthcheck` + `condition: service_healthy`** — запуск ждёт готовности. Наиболее чистое решение для Compose; именно оно у нас в основном `compose.yaml` (шаг 8.6).

Починим третьим способом — добавим в `db` проверку, а в `api` условие:

```bash run
cd ~/docker-lab/coffeeshop
docker compose -p broken -f compose.broken.yaml down -v > /dev/null 2>&1
cat > compose.broken.yaml <<'EOF'
name: broken

services:
  db:
    image: postgres:18
    environment:
      POSTGRES_USER: coffee
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: coffee
    volumes:
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 2s
      timeout: 3s
      retries: 15
  api:
    build: ./api
    environment:
      DB_HOST: db
      DB_PASSWORD: secret
    depends_on:
      db:
        condition: service_healthy
EOF
docker compose -p broken -f compose.broken.yaml up -d 2>&1 | tail -3
sleep 3
docker compose -p broken -f compose.broken.yaml ps --format 'table {{.Service}}\t{{.Status}}'
docker compose -p broken -f compose.broken.yaml logs api
```

```out auto
```

Теперь `api` стартует только после `healthy` у `db` и сразу видит базу: в логе — `база доступна` и `CoffeeShop API слушает порт 3000`. Уберём тестовый проект и файл (основной стек из шага 8.6 остаётся работать):

```bash run
cd ~/docker-lab/coffeeshop
docker compose -p broken -f compose.broken.yaml down -v
rm compose.broken.yaml
docker compose ps --format 'table {{.Service}}\t{{.Status}}'
```

```out auto
```

### why
Эту ошибку делают **все**: на твоём мощном компьютере база иногда успевает, а на сервере или в CI — нет, и «то работает, то не работает». Устойчивое решение — не надеяться на скорость, а явно описать условие готовности. А алгоритм поиска причины «не стартует» — всегда тот же: **`ps -a` → `logs` → читаем сообщение справа налево**.

### deep Если не получилось
- **`api` не падает и в сломанном варианте** — база успела проснуться; удали `-v`-том и запусти заново или замедли базу (на медленной машине гонка воспроизводится надёжнее).
- **`dependency failed to start`** — `healthcheck` у `db` не стал `healthy`: смотри `docker compose logs db`.
- **Образ `api` пересобирается дольше обычного** — нормально для первого раза в проекте `broken`.

### quiz
- Почему `depends_on: [db]` не спасает от `ECONNREFUSED`?
- Назови три способа справиться с гонкой запуска и выбери лучший для Compose.
- Какие две команды ты запускаешь первыми, когда сервис упал?

### outro
:::tip Приёмка сессии 8
- Ты читаешь и пишешь YAML (словари, списки, якоря) и проверяешь файл командой `docker compose config`.
- Ты переводишь `docker run` в `compose.yaml` и называешь соответствие ключей флагам.
- Ты пользуешься `up -d`, `ps`, `logs`, `exec`, `run --rm`, `down` и отличаешь `down` от `down -v`.
- Ты понимаешь, откуда берутся значения переменных: оболочка, `.env`, `environment`, `env_file`, и используешь `${VAR:-x}` и `${VAR:?msg}`.
- Ты объясняешь разницу между «запущен» и «готов» и настраиваешь `healthcheck` + `condition: service_healthy`.
- `docker compose up -d --build` в `~/docker-lab/coffeeshop` поднимает сайт, API, базу и Adminer; заказы переживают `docker compose down`.
- Ты чинишь «приложение стартует раньше БД» по цепочке `ps -a` → `logs` → `healthcheck`.
:::
