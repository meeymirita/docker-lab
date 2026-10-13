# Сессия 11 · Итоговый проект CoffeeShop
dur: ~4 ч

## 11.1 Финальная проверка образов: не root, без уязвимостей | short: Образы для релиза | est: ~45 мин
### intro
**Слова шага:** *релизный образ*, *non-root*, *`nginx-unprivileged`*, *сканер*, *`HEALTHCHECK`*.

:::tip Если совсем просто
Перед открытием кофейни — **проверка пожарной инспекции**: выходы свободны, проводка без дыр, у каждого сотрудника свой пропуск, а не «директорский». Сегодня мы проверяем два наших образа так же строго, как перед настоящим релизом, и исправляем то, что найдёт сканер.
:::

В этой сессии мы собираем итог лабы: **образы, которые не стыдно выложить в продакшн**. Критерии «релизного» образа (мы их все уже разбирали):

1. **Не root** (шаги 4.2, 5.4).
2. **Минимум лишнего** — multi-stage, подходящая база (5.2).
3. **Сканер без серьёзных находок** или каждая находка объяснена (5.5).
4. **`HEALTHCHECK`**/`healthcheck` — чтобы «жив» был не словом, а проверкой (8.5).
5. **Закреплённые версии** баз и пакетов, без `latest` (10.4).

Проверим текущее состояние. Стек из прошлой сессии остановлен, образы `coffeeshop-api` и `coffeeshop-web` собраны Compose. Просканируем сайт (Trivy, шаг 5.5) и посмотрим, кто в нём запускается:

```bash run
cd ~/docker-lab/coffeeshop
docker compose build web > /dev/null 2>&1
echo "--- web: найденные HIGH/CRITICAL:"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --quiet --format json coffeeshop-web:latest | jq -r '.Results[] | .Vulnerabilities[]? | "\(.PkgName)  \(.VulnerabilityID)  (исправлено в \(.FixedVersion // "нет"))"' | sort -u
echo "--- web: пользователь процесса в образе:"
docker image inspect --format 'User="{{.Config.User}}"' coffeeshop-web:latest
echo "--- api: пользователь процесса в образе:"
docker image inspect --format 'User="{{.Config.User}}"' coffeeshop-api:latest
```

### result
```out auto
```

У образа сайта (`nginx:1.30-alpine`) сканер нашёл серьёзные уязвимости в системных пакетах базы, а поле `User` пустое: главный процесс `nginx` стартует от **root** (рабочие процессы дальше переходят на пользователя `nginx`, но «мастер» остаётся root). У API (`distroless`) пользователь задан — `nonroot`. Исправим сайт: заменим базу на **`nginxinc/nginx-unprivileged`** — официальный вариант nginx, который целиком работает от обычного пользователя и на порту **8080** (порты ниже 1024 обычному пользователю без особых прав недоступны). Меняем три файла: `Dockerfile` (база и `HEALTHCHECK`), `nginx.conf` (порт) и `.env`/`compose.yaml` (проброс `8080:8080`):

```bash run
cd ~/docker-lab/coffeeshop/web
cat > Dockerfile <<'EOF'
FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY src ./src
RUN npm run build

FROM nginxinc/nginx-unprivileged:1.30-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY --from=build /app/dist/app.js /usr/share/nginx/html/app.js
EXPOSE 8080
HEALTHCHECK --interval=5s --timeout=3s --retries=5 \
  CMD wget -qO- http://localhost:8080/ > /dev/null || exit 1
EOF
sed -i 's/listen 80;/listen 8080;/' nginx.conf
grep -n listen nginx.conf
cd ..
sed -i 's#"${WEB_PORT:-8080}:80"#"${WEB_PORT:-8080}:8080"#' compose.yaml
grep -n 'WEB_PORT' compose.yaml
docker compose build web > /dev/null 2>&1
echo "--- web после замены:"
docker image inspect --format 'User="{{.Config.User}}"' coffeeshop-web:latest
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --quiet coffeeshop-web:latest | grep Total || echo "серьёзных уязвимостей не найдено"
```

```out auto
```

Теперь `User="101"` (пользователь `nginx` в образе) и сканер серьёзных уязвимостей не находит. В `nginx.conf` слушаем порт 8080, в `compose.yaml` пробросили `8080:8080`. (Команда `sed -i` правит файлы на месте — на Mac у BSD-`sed` для этого нужен пустой аргумент `sed -i ''`, либо просто отредактируй файлы вручную.) У API проверим то же самое — образ чистый:

```bash run
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --quiet coffeeshop-api:latest | grep Total || echo "api: серьёзных уязвимостей не найдено"
docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}' | grep -E 'REPOSITORY|^coffeeshop-(api|web)'
```

```out auto
```

Оба образа готовы: у каждого пользователь без прав root, сканер чист. Размеры скромные: API на distroless с Node, сайт — nginx со статикой (шаг 5.6).

### why
Релиз — это момент, когда «работает» превращается в «безопасно и предсказуемо работает». Сканер и проверка пользователя занимают минуту, а исправленная находка до выкладки стоит несоизмеримо меньше, чем исправление после инцидента. Заметь, что исправление нашлось **заменой базового образа**, а не правкой нашего кода: так бывает чаще всего.

### deep Команда по частям
`jq -r '.Results[] | .Vulnerabilities[]? | "\(.PkgName)  \(.VulnerabilityID)  (исправлено в \(.FixedVersion // "нет"))"'`: из JSON-отчёта Trivy берём каждую уязвимость и печатаем имя пакета, номер CVE и версию с исправлением (`// "нет"` — если поле пустое). `sort -u` убирает повторы. `docker image inspect --format 'User="{{.Config.User}}"'` показывает пользователя, записанного в образе.

### deep Как ещё можно
- **Закрепить версию сильнее:** в `FROM` указать digest: `FROM nginxinc/nginx-unprivileged:1.30-alpine@sha256:…` (шаг 10.4).
- **Если находки остались:** обнови базу (`docker pull`) и пересобери; если исправления нет — запиши причину принятого риска в `README`/в CI-правило.
- **Автоматически:** сканирование в CI (шаг 10.6) с `exit-code: 1` — сборка падает, если найдено CRITICAL.

### deep Если не получилось
- **`nginx: [emerg] bind() to 0.0.0.0:80 failed (13: Permission denied)`** — в `nginx.conf` остался порт 80, а процесс не root: порт должен быть выше 1023 (8080).
- **Сайт на `localhost:8080` не открывается** — проброс остался `8080:80`; должен быть `8080:8080` (порт слева — на Mac, справа — в контейнере).
- **`wget: not found` в `HEALTHCHECK`** — в Alpine-образе `wget` (busybox) есть; в distroless его нет (там проверку делают программой приложения).

### quiz
- Почему nginx из обычного образа считается процессом от root и как это исправляет `nginx-unprivileged`?
- Какой порт слушает `nginx-unprivileged` и почему не 80?
- Что ты делаешь, если сканер нашёл серьёзную уязвимость в базовом образе?

### links
- https://hub.docker.com/r/nginxinc/nginx-unprivileged | образ nginx-unprivileged | nginx-unprivileged
- https://docs.docker.com/build/building/best-practices/ | рекомендации по Dockerfile | Dockerfile best practices

## 11.2 Итоговые Compose-файлы: dev, prod, защита | short: Итоговый compose | est: ~50 мин
### intro
**Слова шага:** *`read_only`*, *`tmpfs`*, *`cap_drop`*, *`security_opt`*, *`pids_limit`*, *`compose.prod.yaml`*.

:::tip Если совсем просто
В шаге 9.6 мы разделили «репетицию» и «рабочий день». Теперь в «рабочем дне» добавим **замки и ограничения** из сессии 5: файловая система закрыта, лишних прав нет, процессов не больше сотни. Готовая кофейня должна держаться даже если кто-то попробует выломать дверь.
:::

Соберём окончательные файлы. **Основной** (`compose.yaml`) — без изменений по смыслу, но с проверкой готовности для сайта. **Dev-накладка** (`compose.override.yaml`) — как была (порт базы, Adminer). **Prod-накладка** (`compose.prod.yaml`) — теперь с защитой: `read_only` + `tmpfs` (шаг 5.4), `cap_drop: [ALL]`, `no-new-privileges`, лимиты процессов и памяти, перезапуск и ограничение логов (шаг 9.4). Для базы данных `read_only` не включаем: PostgreSQL пишет в служебные папки, поэтому её защищают лимитами и отсутствием опубликованных портов.

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
      - "${WEB_PORT:-8080}:8080"
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
cat > compose.prod.yaml <<'EOF'
x-prod: &prod
  restart: unless-stopped
  logging:
    driver: json-file
    options:
      max-size: "10m"
      max-file: "3"
  security_opt:
    - no-new-privileges:true

x-locked: &locked
  <<: *prod
  read_only: true
  cap_drop: [ALL]
  pids_limit: 100

services:
  db:
    <<: *prod
    mem_limit: 512m
    stop_grace_period: 30s
  api:
    <<: *locked
    mem_limit: 256m
    environment:
      NODE_ENV: production
  web:
    <<: *locked
    mem_limit: 128m
    tmpfs:
      - /tmp
EOF
docker compose config -q && echo "dev: compose.yaml + override корректны"
docker compose -f compose.yaml -f compose.prod.yaml config -q && echo "prod: compose.yaml + compose.prod.yaml корректны"
```

### result
```out auto
```

Оба режима собираются без ошибок. Запустим **боевой режим** с защитой и проверим, что приложение работает **в полностью «закрытом» контейнере**:

```bash run
cd ~/docker-lab/coffeeshop
docker compose -f compose.yaml -f compose.prod.yaml up -d --build > /dev/null 2>&1
sleep 5
docker compose -f compose.yaml -f compose.prod.yaml ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
echo "--- сайт и API через сайт:"
curl -s -o /dev/null -w 'сайт: HTTP %{http_code}\n' http://localhost:8080/
curl -s -w '\n' http://localhost:8080/api/menu
echo "--- защита на самом деле включена:"
docker inspect --format '{{.Name}}  read_only={{.HostConfig.ReadonlyRootfs}}  cap_drop={{.HostConfig.CapDrop}}  pids={{.HostConfig.PidsLimit}}  mem={{.HostConfig.Memory}}' coffeeshop-api-1 coffeeshop-web-1
```

```out auto
```

Сайт и API работают при включённых `read_only`, `cap_drop: [ALL]` и лимитах — значит, мы сделали всё правильно: нигде нет скрытых записей на диск и скрытых требований прав. Если бы nginx не получил `tmpfs: /tmp` (его временные файлы и PID лежат там), он бы не запустился с ошибкой `Read-only file system` — такая поломка встретится в Production Hell (шаг 11.6).

### why
Это итог вашей работы над безопасностью: **основной файл описывает приложение, prod-накладка превращает его в «закрытый» боевой режим**. И всё проверено: ограничения не «записаны на бумаге», а действуют (последний `inspect` показывает значения). Принцип «каждому ровно столько, сколько нужно» теперь записан в одном месте.

### deep Команда по частям
`x-locked: &locked` с `<<: *prod` — вложенные заготовки: `locked` включает всё из `prod` и добавляет закрытие. В сервисе `<<: *locked` подставляет оба набора. `read_only: true` — корневая файловая система только для чтения; `tmpfs: [/tmp]` — временная папка в памяти; `cap_drop: [ALL]` — убрать все capabilities; `pids_limit: 100` — не более 100 процессов; `security_opt: [no-new-privileges:true]` — запретить повышение прав.

### deep Как ещё можно
- **Запись, которой не избежать:** если приложение пишет в папку, дай ей `tmpfs` или именованный том (шаг 7.4); не отключай `read_only` ради этого.
- **Секреты:** вместо `DB_PASSWORD` в окружении можно использовать Compose `secrets:` (файл монтируется в `/run/secrets/…`); для базы PostgreSQL образ умеет читать `POSTGRES_PASSWORD_FILE`.
- **Профиль для разработки вместо override:** то же можно записать через `profiles: [dev]` — выбирай, как удобнее команде.

### deep Если не получилось
- **`api` падает с `EROFS: read-only file system`** — приложение пишет на диск; найди путь в сообщении и вынеси его в `tmpfs`/том.
- **`web` не стартует: `mkdir() "/var/cache/nginx/client_temp" failed (30: Read-only file system)`** — не добавлен `tmpfs: [/tmp]` (в `nginx-unprivileged` временные файлы лежат в `/tmp`).
- **`permission denied` при старте** — `cap_drop: [ALL]` убрал право, которое нужно приложению; добавляй по одному (`cap_add`).

### quiz
- Чем prod-накладка отличается от основного файла и что она добавляет?
- Почему для `db` мы не включаем `read_only`, а для `api` и `web` — включаем?
- Как проверить, что ограничения действительно применились, а не только записаны в файле?

### links
- https://docs.docker.com/reference/compose-file/services/ | ключи сервиса Compose | Compose services
- https://docs.docker.com/engine/security/ | безопасность Docker | Docker security

## 11.3 Чек-лист релиза: автоматические проверки | short: Чек-лист релиза | est: ~45 мин
### intro
**Слова шага:** *релиз*, *чек-лист*, *дымовой тест (smoke test)*, *код выхода*, *`sh`-скрипт*.

:::tip Если совсем просто
Пилот перед взлётом читает **карточку проверок**: «шасси? — есть. Топливо? — есть». Мы тоже напишем карточку, но такую, которую читает **компьютер**: он сам пройдёт по пунктам и скажет «можно» или «стоп». Так не зависит от настроения и усталости.
:::

Рабочий образ — это ещё не готовый релиз. Перед тем как поставить тег версии, проверяем один и тот же список. Если проверять руками, обязательно забудешь пункт, поэтому записываем в скрипт. **Smoke test** («дымовой тест») — быстрая проверка, что система вообще работает: «запустили — пошёл ли дым». Скрипт `release-check.sh` проверяет шесть вещей и завершается с кодом `0` (всё хорошо) или `1` (что-то не так) — по этому коду его может использовать и CI.

```bash run
cd ~/docker-lab/coffeeshop
cat > release-check.sh <<'EOF'
#!/bin/sh
# Чек-лист релиза CoffeeShop: запускать из папки проекта, когда стек запущен в prod-режиме.
FAIL=0
ok()  { echo "  ✔ $1"; }
bad() { echo "  ✘ $1"; FAIL=1; }

echo "1. Конфигурация корректна (dev и prod)"
docker compose config -q && docker compose -f compose.yaml -f compose.prod.yaml config -q && ok "compose config" || bad "compose config"

echo "2. Нет тега latest в Compose-файлах и Dockerfile"
if grep -nE ':latest' compose*.yaml api/Dockerfile web/Dockerfile >/dev/null 2>&1; then bad "найден :latest"; else ok "latest не используется"; fi

echo "3. Секреты не в репозитории (.env в .gitignore)"
grep -qx '.env' .gitignore && ok ".env в .gitignore" || bad ".env не в .gitignore"

echo "4. Образы работают не от root"
for img in coffeeshop-api:latest coffeeshop-web:latest; do
  u=$(docker image inspect --format '{{.Config.User}}' "$img")
  case "$u" in ""|0|root) bad "$img запускается от root";; *) ok "$img: пользователь $u";; esac
done

echo "5. Сканер: нет HIGH/CRITICAL"
for img in coffeeshop-api:latest coffeeshop-web:latest; do
  n=$(docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --quiet --format json "$img" | jq '[.Results[]?.Vulnerabilities[]?] | length')
  [ "$n" = "0" ] && ok "$img: уязвимостей нет" || bad "$img: найдено $n"
done

echo "6. Дымовой тест: сайт, API, база"
curl -fsS -o /dev/null http://localhost:8080/ && ok "сайт отвечает" || bad "сайт не отвечает"
cnt=$(curl -fsS http://localhost:8080/api/menu | jq 'length' 2>/dev/null)
[ "$cnt" = "3" ] && ok "меню из базы: $cnt позиции" || bad "меню не получено"
id=$(curl -fsS -X POST -H 'Content-Type: application/json' -d '{"menu_id":1}' http://localhost:8080/api/orders | jq -r '.id' 2>/dev/null)
[ -n "$id" ] && [ "$id" != "null" ] && ok "заказ создан (id $id)" || bad "заказ не создан"

echo
if [ "$FAIL" = "0" ]; then echo "РЕЛИЗ МОЖНО ВЫПУСКАТЬ"; else echo "СТОП: есть замечания"; fi
exit $FAIL
EOF
chmod +x release-check.sh
./release-check.sh
echo "код выхода: $?"
```

### result
```out auto
```

Все шесть групп проверок пройдены, скрипт сообщает «РЕЛИЗ МОЖНО ВЫПУСКАТЬ», а **код выхода `0`**. Заметь, как скрипт устроен: функции `ok` и `bad` печатают галочку или крестик, `bad` ещё и запоминает «были замечания» (`FAIL=1`), а в конце `exit $FAIL` отдаёт итог системе. Проверим, что скрипт действительно **ловит** проблемы: нарочно сломаем один пункт — уберём `.env` из `.gitignore` — и запустим только третью проверку так, как она описана в скрипте:

```bash run
cd ~/docker-lab/coffeeshop
cp .gitignore .gitignore.bak
printf 'node_modules\n' > .gitignore
./release-check.sh > check.txt
code=$?
grep -E '^3\.|✘|СТОП|РЕЛИЗ' check.txt
echo "код выхода: $code"
rm check.txt
mv .gitignore.bak .gitignore
```

```out auto
```

Скрипт нашёл `✘ .env не в .gitignore`, сообщил «СТОП» и вернул ненулевой код. Вернули файл на место. Такой скрипт кладут в репозиторий рядом с `compose.yaml`, и перед тегом версии его запускают одной командой.

### why
Проверки, записанные кодом, не забываются и не зависят от человека. Сегодня это скрипт на `sh`, завтра те же пункты поедут в GitHub Actions как шаги конвейера (шаг 10.6), и релиз перестанет быть «ритуалом с галочками». Это и есть «дисциплина» в разработке: не вспоминать, а запускать.

### deep Команда по частям
`case "$u" in ""|0|root) … ;; *) … ;; esac` — оператор выбора в оболочке: если пользователь пуст, `0` или `root` — ошибка, иначе — норма. `docker image inspect --format '{{.Config.User}}' "$img"` — пользователь, записанный в образе. `[ "$n" = "0" ] && ok … || bad …` — «если равно 0 — ок, иначе — ошибка». `exit $FAIL` — завершить скрипт с кодом `0` или `1`.

### deep Как ещё можно
- **Добавить пункты:** размер образов не больше порога (`docker image inspect --format '{{.Size}}'`), `docker compose ps` — все сервисы `healthy`, отсутствие `privileged`.
- **Запускать автоматически:** шаг `run: ./release-check.sh` в workflow перед публикацией.
- **Готовые инструменты:** `hadolint` — линтер Dockerfile, `dockle` — проверка образов на лучшие практики; `docker scout` — рекомендации по обновлению баз.

### deep Если не получилось
- **`jq: command not found`** — на Mac установи `brew install jq` (в методичке команда выполнена в контейнере, где `jq` уже есть).
- **`✘ сайт не отвечает`** — стек не запущен в prod-режиме: сначала `docker compose -f compose.yaml -f compose.prod.yaml up -d`.
- **Скрипт «не запускается»: `Permission denied`** — нет права на выполнение: `chmod +x release-check.sh`.

### quiz
- Зачем записывать проверки релиза скриптом, а не выполнять их руками?
- Что такое код выхода скрипта и как его использует CI?
- Какие шесть групп проверок содержит `release-check.sh`?

### links
- https://github.com/hadolint/hadolint | hadolint — линтер Dockerfile | hadolint
- https://github.com/goodwithtech/dockle | dockle — проверка образов | dockle

## 11.4 Релиз из registry: стек на готовых образах | short: Релиз из registry | est: ~50 мин
### intro
**Слова шага:** *релизный компоуз-файл*, *`image:` вместо `build:`*, *`VERSION`*, *«с чистой машины»*, *push и pull версий*.

:::tip Если совсем просто
До сих пор мы **собирали кофе на месте** (`build:`). На настоящем сервере кофе привозят **готовым в коробках** (`image:`) — собирать там нечем и незачем. Мы упакуем коробки, отнесём на склад (registry) и запустим кофейню **только из коробок**, как это будет на сервере.
:::

На сервере исходного кода и сборочных инструментов нет — есть только Docker и registry. Поэтому нужен **релизный** Compose-файл: вместо `build:` у сервисов стоит `image:` с адресом и версией образа. Версию и адрес registry берём из переменных, чтобы тот же файл годился и для GHCR, и для нашего локального registry:

```bash run
cd ~/docker-lab/coffeeshop
cat > compose.release.yaml <<'EOF'
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
    restart: unless-stopped
    networks: [back]

  api:
    image: ${REGISTRY:?Укажи REGISTRY}/coffeeshop-api:${VERSION:?Укажи VERSION}
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
    read_only: true
    cap_drop: [ALL]
    security_opt: ["no-new-privileges:true"]
    restart: unless-stopped
    networks: [front, back]

  web:
    image: ${REGISTRY}/coffeeshop-web:${VERSION}
    ports:
      - "${WEB_PORT:-8080}:8080"
    depends_on:
      api:
        condition: service_healthy
    read_only: true
    tmpfs: [/tmp]
    cap_drop: [ALL]
    security_opt: ["no-new-privileges:true"]
    restart: unless-stopped
    networks: [front]

networks:
  front:
  back:

volumes:
  pgdata:
EOF
REGISTRY=localhost:5050 VERSION=1.0.0 docker compose -f compose.release.yaml config -q && echo "compose.release.yaml корректен"
```

### result
```out auto
```

Теперь «выпустим версию 1.0.0» вручную — так же, как это сделает конвейер: поднимем свой registry, **поставим теги** и **отправим** образы. Чтобы доказать, что стек будет работать **только из registry**, удалим локально собранные образы и всю прежнюю работающую версию:

```bash run
cd ~/docker-lab/coffeeshop
docker compose -f compose.yaml -f compose.prod.yaml down
docker run -d --name registry -p 5050:5000 -v registry-data:/var/lib/registry registry:2 > /dev/null
sleep 2
for s in api web; do
  docker tag coffeeshop-$s:latest localhost:5050/coffeeshop-$s:1.0.0
  docker push localhost:5050/coffeeshop-$s:1.0.0 2>&1 | tail -1
done
echo "--- удаляем локально собранные образы:"
docker rmi coffeeshop-api:latest coffeeshop-web:latest localhost:5050/coffeeshop-api:1.0.0 localhost:5050/coffeeshop-web:1.0.0 > /dev/null
docker images --format '{{.Repository}}' | grep -c '^coffeeshop-' || true
```

```out auto
```

Два образа ушли в registry с версией `1.0.0`; локальных копий нет. Теперь запустим стек **из registry** — только релизным файлом, без исходников и сборки:

```bash run
cd ~/docker-lab/coffeeshop
export REGISTRY=localhost:5050 VERSION=1.0.0
docker compose -f compose.release.yaml up -d 2>&1 | grep -iE 'pull|error' | head -4
sleep 8
docker compose -f compose.release.yaml ps --format 'table {{.Service}}\t{{.Image}}\t{{.Status}}'
curl -s -w '\n' http://localhost:8080/api/menu
```

```out auto
```

Образы `coffeeshop-api` и `coffeeshop-web` скачаны **из registry** (`Pulled`), стек поднялся и отдаёт меню — это и есть «запуск на чистой машине»: на ней нет ни кода, ни сборки, только Docker, `compose.release.yaml`, `.env` и доступ к registry. На настоящем сервере меняется только адрес: `REGISTRY=ghcr.io/<логин>` и `VERSION=1.0.0`, образы приходят из GHCR (шаги 10.3 и 10.6). Обновление версии — смена одной переменной:

```bash
export VERSION=1.0.1
docker compose -f compose.release.yaml up -d   # скачает 1.0.1 и пересоздаст только изменившиеся сервисы
```

Откат — то же самое, с прежним номером: `VERSION=1.0.0`. Поэтому точные теги мы не перезаписываем (шаг 10.4). Остановим стек и уберём учебный registry:

```bash run
cd ~/docker-lab/coffeeshop
docker compose -f compose.release.yaml down
docker rm -f registry > /dev/null
docker volume rm registry-data
```

```out auto
```

### why
Это главная разница «разработки» и «эксплуатации»: на сервере **не собирают**, а **запускают проверенные образы**. Один и тот же образ работает у тебя, на проверке и в продакшне, а откат и обновление — смена номера версии. Вся цепочка сессии 10 (теги, registry, CI) нужна ради этого.

### deep Команда по частям
`image: ${REGISTRY:?Укажи REGISTRY}/coffeeshop-api:${VERSION:?Укажи VERSION}`: собираем адрес образа из двух обязательных переменных (`:?` — остановиться с сообщением, если не заданы). `export REGISTRY=… VERSION=…` — положить переменные в окружение оболочки на время сеанса, чтобы Compose их подставил. `docker compose … up -d | grep -iE 'pull|error'` — оставляем строки о скачивании и ошибках.

### deep Как ещё можно
- **Переменные в `.env`:** строки `REGISTRY=ghcr.io/<логин>` и `VERSION=1.0.0` в `.env` на сервере — тогда команда короче.
- **Закрепить по digest:** `image: …/coffeeshop-api:1.0.0@sha256:…`.
- **Приватный registry:** перед `up` выполнить `docker login` (шаги 10.3 и 10.7).
- **Автоматическое обновление:** на серверах это делают CD-системы (деплой по тегу) или инструменты вроде Watchtower; в этой лабе — вручную.

### deep Если не получилось
- **`pull access denied` / `unauthorized`** — образ приватный или имя неверно: `docker login`, проверь `REGISTRY` и `VERSION`.
- **`variable REGISTRY is required`** — не заданы переменные окружения (шаг 8.4).
- **Запустилась старая версия** — Compose использует образ, который уже есть локально, при том же теге; для свежей версии сделай `docker compose pull` или смени `VERSION`.

### quiz
- Чем `compose.release.yaml` отличается от `compose.yaml` и почему на сервере нужен именно он?
- Как обновить стек до версии `1.0.1` и как откатиться?
- Как мы доказали, что стек запускается только из registry?

### links
- https://docs.docker.com/compose/how-tos/production/ | Compose в продакшне | Use Compose in production

## 11.5 Упаковка проекта: starter/ и дымовой тест | short: starter/ | est: ~50 мин
### intro
**Слова шага:** *starter*, *чистая копия проекта*, *`.env.example`*, *дымовой тест*, *воспроизводимость*.

:::tip Если совсем просто
Теперь нужно собрать **коробку «CoffeeShop — наборы для следующих уроков»**: сложить в неё всё нужное и ничего лишнего (никаких черновиков и паролей) — и проверить, что **с нуля, из пустой папки** всё открывается и работает. Эту коробку возьмут Traefik, Kubernetes и Ansible.
:::

Лабы цепочки (Traefik, Kubernetes, Ansible) используют **тот же проект CoffeeShop**. Чтобы они не зависели от твоих черновиков, из итоговой версии собирают **`starter/`** — аккуратную папку, которая запускается одной командой. Правила: **только нужное** (исходники, Compose-файлы, SQL, workflow, README, скрипты), **никаких секретов** (`.env` не копируем — вместо него `.env.example`), **никаких экспериментов** (`Dockerfile.alpine`, старый `entrypoint.sh`).

Соберём `starter` копированием «с исключениями» (`tar` — упаковщик; ключи `--exclude` пропускают ненужное). Сначала поднимем `.env.example` в актуальное состояние и напишем README с краткой инструкцией:

```bash run
cd ~/docker-lab/coffeeshop
printf 'DB_USER=coffee\nDB_PASSWORD=change-me\nDB_NAME=coffee\nWEB_PORT=8080\n' > .env.example
cat > README.md <<'EOF'
# CoffeeShop — учебный стек

Сайт (nginx), API (Node.js), база (PostgreSQL 18), Adminer (только для разработки).

### Быстрый старт

    cp .env.example .env        # задай свой DB_PASSWORD
    docker compose up -d --build
    ./smoke.sh                  # дымовой тест

Сайт: http://localhost:8080 · Adminer (dev): http://localhost:8081

### Режимы

- разработка: `docker compose up -d` (подмешивается compose.override.yaml)
- боевой: `docker compose -f compose.yaml -f compose.prod.yaml up -d`
- из готовых образов: `REGISTRY=ghcr.io/<логин> VERSION=1.0.0 docker compose -f compose.release.yaml up -d`

### Проверки

    ./release-check.sh          # чек-лист релиза (стек должен работать в prod-режиме)

`.env` с паролем в git не коммитится.
EOF
cat > smoke.sh <<'EOF'
#!/bin/sh
# Дымовой тест CoffeeShop: стек уже запущен.
set -e
URL=${1:-http://localhost:8080}
curl -fsS -o /dev/null "$URL/" && echo "ok  сайт отвечает"
n=$(curl -fsS "$URL/api/menu" | jq 'length')
[ "$n" -ge 1 ] && echo "ok  меню из базы: $n позиции"
id=$(curl -fsS -X POST -H 'Content-Type: application/json' -d '{"menu_id":1}' "$URL/api/orders" | jq -r '.id')
echo "ok  заказ создан, id $id"
echo "SMOKE: всё в порядке"
EOF
chmod +x smoke.sh
mkdir -p ~/docker-lab/starter
tar -cf - --exclude=.env --exclude=node_modules --exclude=Dockerfile.alpine --exclude=entrypoint.sh --exclude=backup.sql --exclude=pgdata.tgz --exclude=.gitignore.bak . | tar -xf - -C ~/docker-lab/starter
printf '.env\nnode_modules\n' > ~/docker-lab/starter/.gitignore
cd ~/docker-lab/starter
find . -type f | sort
```

### result
```out auto
```

В `starter/` — исходники `api` и `web`, SQL базы, Compose-файлы (основной, override, prod, release), workflow публикации, README, `smoke.sh`, `release-check.sh`, `.env.example` и `.gitignore`. **Нет** `.env` (пароля), `node_modules`, черновиков и личных бэкапов базы (`backup.sql`, `pgdata.tgz` из шага 7.6). Теперь главное — **проверим с нуля**: скопируем `starter` в совершенно чистую папку, как это сделает человек, впервые получивший проект, и пройдём по его README:

```bash run
cd ~/docker-lab/coffeeshop
docker compose -f compose.yaml -f compose.prod.yaml down > /dev/null 2>&1
rm -rf ~/docker-lab/starter-test && cp -r ~/docker-lab/starter ~/docker-lab/starter-test
cd ~/docker-lab/starter-test
cp .env.example .env
docker compose -p starter-test up -d --build > /dev/null 2>&1
sleep 6
docker compose -p starter-test ps --format 'table {{.Service}}\t{{.Status}}'
./smoke.sh
docker compose -p starter-test down -v > /dev/null 2>&1
cd ~ && rm -rf ~/docker-lab/starter-test
```

```out auto
```

С чистой копии: `cp .env.example .env` → `docker compose up -d --build` → `./smoke.sh` — стек поднялся (мы добавили `-p starter-test`, чтобы тестовый стек не пересёкся с твоим основным проектом `coffeeshop` и не тронул его том с данными: у человека, получившего `starter/` с нуля, такого проекта нет и флаг не нужен), а дымовой тест прошёл. Значит, `starter/` самодостаточен: любой, кто его получит, запустит CoffeeShop за минуту, и именно с него начнут следующие лабы цепочки (Traefik, Kubernetes, Ansible).

### why
«Работает у меня» превращается в «работает у любого», когда проект упакован и проверен **с чистого листа**. Проверка копии в новой папке выявляет всё, что было спрятано: файл, который лежал только у тебя, переменную, которую ты когда-то задала в оболочке, зависимость от соседней папки. Если чистая копия поднимается — проект действительно переносим.

### deep Команда по частям
`tar -cf - --exclude=.env … . | tar -xf - -C ~/docker-lab/starter`: первый `tar` упаковывает текущую папку (`-c` создать, `-f -` в стандартный вывод) без перечисленных файлов, второй распаковывает поток (`-x`) в целевую папку (`-C`). Это переносимый способ копирования «с исключениями», когда нет `rsync`. `find . -type f | sort` — список всех файлов с сортировкой.

### deep Как ещё можно
- **`git`-репозиторий:** `starter` в git — естественное хранилище; `.gitignore` уже исключает `.env`.
- **Сравнить с исходной папкой:** `diff -rq ~/docker-lab/coffeeshop ~/docker-lab/starter` покажет отличия.
- **Опубликовать:** репозиторий на GitHub (без `.env`) + тег `v1.0.0` → workflow из шага 10.6 соберёт образы.

### deep Если не получилось
- **`./smoke.sh: Permission denied`** — нет права на выполнение: `chmod +x smoke.sh`.
- **Стек из `starter-test` не поднимается из-за порта** — предыдущий стек ещё работает: останови его (`docker compose … down`).
- **В `starter` попал `.env`** — исключение не сработало (опечатка в `--exclude`); удали файл и проверь `find . -name .env`.

### quiz
- Что должно и что не должно попасть в `starter/`?
- Почему проект проверяют копированием в **чистую** папку?
- Какие три команды запускает человек, впервые получивший `starter/`?

### links
- https://docs.docker.com/compose/ | документация Compose | Docker Compose

## 11.6 🔨 Production Hell 2: пять поломок без подсказок | short: Production Hell 2 | est: ~90 мин
### intro
**Слова шага:** *диагностика без подсказок*, *symptom → cause → fix*, *слои*.

:::tip Если совсем просто
Второй экзамен. Теперь поломки **другие** и спрятаны в других слоях. Правила те же: идёшь по симптомам, начинаешь с `ps -a` и `logs`, чинишь по одной. Подсказки и разбор — под спойлерами. Читать их до попытки — значит украсть у себя урок.
:::

Мы возьмём итоговый `starter/` и сломаем его пятью новыми способами: поломка в **реестре образов**, в **готовности сервисов**, в **ограничениях безопасности**, в **ресурсах** и в **настройках приложения**. Цель: `./smoke.sh` печатает «SMOKE: всё в порядке», `docker compose ps` — все сервисы здоровы. Готовим аварийный стек:

```bash run
rm -rf ~/docker-lab/hell2 && cp -r ~/docker-lab/starter ~/docker-lab/hell2
cd ~/docker-lab/hell2
cp .env.example .env
sed -i 's/DB_PASSWORD=change-me/DB_PASSWORD=secret/' .env
# --- поломка 1: опечатка в теге образа
sed -i 's#image: postgres:18#image: postgres:18-alpin#' compose.yaml
# --- поломка 2: сервис ждёт готовности, но у базы нет healthcheck
awk 'BEGIN{skip=0} /healthcheck:/ && prev ~ /init.sql/ {skip=1} skip==1 && /networks: \[back\]/ {skip=0} skip==0 {print} {prev=$0}' compose.yaml > c.tmp && mv c.tmp compose.yaml
# --- поломка 3: nginx read_only без tmpfs
sed -i '/tmpfs:/,+1d' compose.prod.yaml
# --- поломка 4: слишком маленький лимит памяти для базы
sed -i 's/mem_limit: 512m/mem_limit: 8m/' compose.prod.yaml
# --- поломка 5: API получает пароль под неверным именем переменной
sed -i 's/DB_PASSWORD: ${DB_PASSWORD}/DB_PASS: ${DB_PASSWORD}/' compose.yaml
ls -a
```

### result
```out auto
```

Готово: папка `~/docker-lab/hell2` — копия стека с пятью подмененными строками. **Правила игры:**

1. Меняй только `compose.yaml`, `compose.prod.yaml` и `.env` (код API, сайта и SQL правильный).
2. Запускай боевой режим под отдельным именем проекта, чтобы не задеть данные основного стека: `docker compose -p hell2 -f compose.yaml -f compose.prod.yaml up -d --build` (все команды — с `-p hell2`).
3. Один симптом за раз: **симптом → `ps -a` → `logs` → причина → правка → повтор**.
4. Финиш: `docker compose -p hell2 -f compose.yaml -f compose.prod.yaml ps` — все сервисы `Up`, у `db`, `api`, `web` — `healthy` (там, где есть проверка), `./smoke.sh` успешен.

Начни с запуска и посмотри на первый симптом:

```bash run
cd ~/docker-lab/hell2
docker compose -p hell2 -f compose.yaml -f compose.prod.yaml up -d --build 2>&1 | tail -4
```

```out auto
```

Первая поломка встретила сразу. Дальше — сама.

### deep Подсказка 1: где искать (открыть, если застряла)
Поломки лежат в разных слоях и показывают себя **по очереди**: **1)** образ не скачивается; **2)** Compose сообщает, что у базы нет проверки здоровья; **3)** база убита ядром за нехватку памяти (код 137) и перезапускается; **4)** API падает при старте с жалобой на пароль; **5)** сайт падает с ошибкой записи в файловую систему.

### deep Подсказка 2: симптомы и места (открыть, если застряла)
- `failed to resolve reference "docker.io/library/postgres:…": … not found` → шаг 3.2 (теги образов).
- `dependency failed to start: container … has no healthcheck configured` → шаг 8.5 (`condition: service_healthy` требует `healthcheck`).
- `db` в состоянии `Restarting (1)`, в логе `Killed` и `child process exited with exit code 137`, а `docker inspect` показывает `OOMKilled=true`; следом `dependency failed to start: container … is unhealthy` → шаг 9.4 (лимит памяти).
- `api` в `Restarting`, в логе `не удалось подключиться к базе: SASL: SCRAM-SERVER-FIRST-MESSAGE: client password must be a string` → шаг 8.4 (имя переменной окружения, которую читает код).
- `web` в `Restarting`, в логе `mkdir() "/tmp/proxy_temp" failed (30: Read-only file system)` → шаги 5.4 и 11.2 (`read_only` требует `tmpfs`).

### deep Разбор: пять поломок и исправления (открыть после попытки)
**1. `postgres:18-alpin`** — опечатка в теге: правильно `postgres:18`.
**2. У `db` нет `healthcheck`**, а `api` ждёт `service_healthy`: вернуть блок `healthcheck` для `db`.
**3. У `web` пропал `tmpfs: [/tmp]`** при `read_only: true`: вернуть.
**4. `mem_limit: 8m` у `db`**: PostgreSQL не помещается в 8 МБ — вернуть `512m`.
**5. `DB_PASS` вместо `DB_PASSWORD`** у `api`: код читает `process.env.DB_PASSWORD`.

Проверим, что именно эти исправления восстанавливают стек (в тестовой среде мы просто возвращаем файлы из `starter/`; у тебя ты правишь строки вручную):

```bash run
cd ~/docker-lab/hell2
docker compose -p hell2 -f compose.yaml -f compose.prod.yaml down -v > /dev/null 2>&1
diff -u ../starter/compose.yaml compose.yaml | grep -E '^[+-] '
diff -u ../starter/compose.prod.yaml compose.prod.yaml | grep -E '^[+-] '
cp ../starter/compose.yaml ../starter/compose.prod.yaml .
docker compose -p hell2 -f compose.yaml -f compose.prod.yaml up -d --build > /dev/null 2>&1
sleep 8
docker compose -p hell2 -f compose.yaml -f compose.prod.yaml ps --format 'table {{.Service}}\t{{.Status}}'
./smoke.sh
docker compose -p hell2 -f compose.yaml -f compose.prod.yaml down -v > /dev/null 2>&1
cd ~ && rm -rf ~/docker-lab/hell2
```

```out auto
```

`diff -u` показывает пять отличий (строки с `-` — правильный вариант из `starter/`, с `+` — сломанный; при удалении блока `healthcheck` и `tmpfs` в списке видны их строки), а после возврата файлов все сервисы поднимаются и `smoke.sh` проходит. Если ты нашла все пять сама, ты умеешь то, ради чего написана лаба: по сообщению в логе находить слой, в котором сломано, и чинить его, не гадая.

### why
Так выглядят настоящие аварии: не «ничего не работает», а пять мелких причин в пяти разных слоях, каждая видна в своём сообщении. Тот, кто умеет читать `ps -a`, `logs` и `inspect`, чинит стек за полчаса; тот, кто пытается «перезапускать всё подряд», — ходит по кругу. Это итог всей лабы, и потому он проверяется без подсказок.

### quiz
- Какими двумя командами ты начинаешь любую диагностику стека?
- По каким сообщениям ты узнала о каждой из пяти поломок?
- Что ты поменяешь в привычках (проверка `config -q`, `.env.example`, чек-лист), чтобы такие поломки ловились до запуска?

### outro
:::tip Приёмка сессии 11
- Образы API и сайта проверены: не root, сканер чист, у сайта проверка здоровья; сайт переведён на `nginx-unprivileged` (порт 8080).
- Итоговые файлы: `compose.yaml`, `compose.override.yaml` (разработка), `compose.prod.yaml` (защита: `read_only`, `cap_drop`, лимиты, логи), `compose.release.yaml` (из registry).
- Скрипт `release-check.sh` проходит все шесть групп проверок и ловит нарушение (код выхода `1`).
- Стек запущен **только из образов registry** (`REGISTRY`, `VERSION`), версия меняется одной переменной.
- Папка `starter/` собрана без секретов и черновиков и проверена с чистого листа: `cp .env.example .env` → `docker compose up -d --build` → `./smoke.sh`.
- Production Hell 2 пройден: пять поломок найдены по сообщениям и исправлены.
:::
