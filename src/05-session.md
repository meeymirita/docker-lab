# Сессия 5 · Оптимизация, multi-stage, безопасность образа
dur: ~4 ч

## 5.1 Что такое «хороший образ» и как его измерять | short: Измеряем образ | est: ~30 мин
### intro
**Слова шага:** *размер образа*, *время сборки*, *поверхность атаки*, *уязвимость (CVE)*, *«до/после»*.

:::tip Если совсем просто
Хороший образ — как хороший рюкзак в поход: в нём **только нужное**. Лишний хлам делает его тяжёлым (долго скачивать), а ещё в хламе могут завестись «жуки» (уязвимости). В этой сессии мы выбрасываем лишнее из нашего образа и записываем цифры «было → стало».
:::

Что считаем у образа:

1. **Размер** — сколько весит на диске и сколько скачивается на сервер. Меньше — быстрее и дешевле.
2. **Время сборки** — холодная (без кэша) и «после правки кода» (с кэшем, шаг 4.7).
3. **Поверхность атаки** — сколько в образе программ и библиотек, которыми можно воспользоваться при взломе: оболочка, менеджер пакетов, лишние утилиты.
4. **Уязвимости (CVE)** — известные дыры в пакетах образа, которые находит сканер (шаг 5.5).
5. **Права** — от кого работает процесс и что ему разрешено (шаг 5.4).

Запишем стартовые цифры для нашего API из шага 4.6 (`coffee-api:2`, Alpine-база с Node). Размер и самые «тяжёлые» слои:

```bash run
cd ~/docker-lab/coffeeshop/api
docker images coffee-api:2
docker history --format 'table {{.Size}}\t{{.CreatedBy}}' coffee-api:2
```

### result
```out auto
```

Образ весит около 250 МБ, и почти всё — это **база** `node:24-alpine` (самые тяжёлые строки — внизу списка: сам Node и его системные файлы). Наши слои — `npm ci` и код — крошечные. Значит, главный рычаг — **что мы берём за основу и что оставляем в итоговом образе**, а не «как ужать наш код». Время холодной сборки (`--no-cache` игнорирует кэш слоёв):

```bash run
cd ~/docker-lab/coffeeshop/api
time docker build -q --no-cache -t coffee-api:2 . > /dev/null
```

```out auto
```

Теперь у нас есть «до». Дальше в сессии мы изменим образ тремя способами и в конце сравним цифры.

### why
Без измерения нельзя понять, стало лучше или нет. Оптимизация вслепую приводит к странным решениям: полдня выбирают между `alpine` и `slim`, а настоящий выигрыш даёт вынесение сборочных инструментов из итогового образа (шаг 5.2).

### deep Команда по частям
`time docker build -q --no-cache -t coffee-api:2 . > /dev/null`: `time` — замерить, сколько работала команда; `-q` — тихий вывод (печатает только идентификатор образа); `--no-cache` — не использовать кэш слоёв; `> /dev/null` — выбросить этот идентификатор; в конце вывод `time` покажет `real` — реальное время.

### deep Как ещё можно
- **Графически:** в Docker Desktop вкладка *Images* показывает размер и найденные уязвимости каждого образа.
- **`dive`:** `dive coffee-api:2` показывает, какие файлы добавил каждый слой (шаг 3.3).
- **Размер в registry:** в Docker Hub отображается сжатый размер (то, что реально скачивают) — он меньше, чем `DISK USAGE`.

### quiz
- Какие пять показателей образа стоит измерять?
- Почему размер нашего образа почти целиком определяется базой, а не нашим кодом?
- Зачем флаг `--no-cache` при замере времени сборки?

### links
- https://docs.docker.com/build/building/best-practices/ | рекомендации по сборке | Build best practices
- https://docs.docker.com/reference/cli/docker/image/history/ | docker history | docker history

## 5.2 Multi-stage: сборка отдельно, запуск отдельно | short: Multi-stage | est: ~50 мин
### intro
**Слова шага:** *multi-stage build*, *stage (этап)*, *`AS`*, *`COPY --from`*, *`--target`*, *distroless*, *`nonroot`*.

:::tip Если совсем просто
Когда строят дом, на участке стоят бетономешалка, леса и мусор. Но жильцам нужен только дом! Multi-stage — это «**стройка** в одном месте, а в готовый дом переносим только результат». Инструменты сборки (компиляторы, `npm`, кэши) остаются на стройке и в итоговый образ не попадают.
:::

```svg
<svg viewBox="0 0 640 215" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Multi-stage: сборка в одном этапе, в итоговый образ попадает только результат" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m1-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m1-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><rect x="10" y="30" width="270" height="150" rx="8" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="145" y="22" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor" fill-opacity="1">Этап 1: «стройка» (build)</text><rect x="28" y="42" width="110" height="36" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="83.0" y="65.0" text-anchor="middle" font-size="12" fill="currentColor">Node + npm</text><rect x="152" y="42" width="110" height="36" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="207.0" y="65.0" text-anchor="middle" font-size="12" fill="currentColor">esbuild</text><rect x="28" y="86" width="110" height="36" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="83.0" y="109.0" text-anchor="middle" font-size="12" fill="currentColor">исходники</text><rect x="152" y="86" width="110" height="36" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="207.0" y="109.0" text-anchor="middle" font-size="12" fill="currentColor">node_modules</text><rect x="60" y="132" width="190" height="36" rx="8" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.5"/><text x="155.0" y="155.0" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor">готовый dist/app.js</text><line x1="280" y1="150" x2="370" y2="150" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)"/><text x="325.0" y="143.0" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">COPY --from</text><rect x="370" y="30" width="260" height="150" rx="8" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="500" y="22" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor" fill-opacity="1">Этап 2: «витрина» (итоговый образ)</text><rect x="400" y="60" width="200" height="40" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="500.0" y="85.0" text-anchor="middle" font-size="13" fill="currentColor">nginx</text><rect x="400" y="120" width="200" height="40" rx="8" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.5"/><text x="500.0" y="145.0" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor">готовый dist/app.js</text><text x="145" y="202" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">остаётся на «стройке» и выбрасывается</text><text x="500" y="202" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">едет на сервер: ничего лишнего</text></svg>
```

В Dockerfile можно писать **несколько `FROM`** — каждый начинает новый **этап (stage)**. Этапу можно дать имя (`FROM … AS имя`), а следующему этапу — забрать из него файлы командой `COPY --from=имя`. В итоговый образ попадёт **только последний этап**; всё остальное нужно лишь на время сборки.

Применим к нашему API. Этап `deps` (на `node:24-alpine`) устанавливает пакеты; итоговый этап — **distroless**-образ `nodejs24` от Google (шаг 3.4): в нём есть Node, но нет оболочки, `npm`, `yarn` и менеджера пакетов. Запускать приложение будет встроенный пользователь `nonroot`.

```bash run
cd ~/docker-lab/coffeeshop/api
cat > Dockerfile.distroless <<'EOF'
FROM node:24-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM gcr.io/distroless/nodejs24-debian13
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY package.json server.js ./
USER nonroot
EXPOSE 3000
CMD ["server.js"]
EOF
docker build -q -f Dockerfile.distroless -t coffee-api:slim .
docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}' | grep -E 'REPOSITORY|coffee-api'
```

### result
```out auto
```

Что нового в Dockerfile. **`AS deps`** — имя первого этапа. **`COPY --from=deps /app/node_modules ./node_modules`** — копируем папку из этапа `deps` (а не из контекста сборки). **`CMD ["server.js"]`** — у distroless-образа `ENTRYPOINT` уже равен `node`, поэтому в `CMD` остаётся только имя файла (итог: `node server.js`, шаг 4.3). Проверим, что приложение работает, останавливается мгновенно и что внутри нет оболочки:

```bash run
docker run -d --name slim -p 3010:3000 coffee-api:slim
sleep 2
curl -s -w '\n' http://localhost:3010/health
docker exec slim sh
time docker stop slim
docker inspect --format 'код выхода: {{.State.ExitCode}}' slim
docker rm slim
```

```out auto
```

Сервис отвечает, останавливается за доли секунды с кодом `0`, а `docker exec slim sh` не находит `sh` (`executable file not found`) — оболочки нет, значит, злоумышленнику, попавшему в контейнер, нечем пользоваться. Размер изменился умеренно: главный выигрыш здесь не в мегабайтах, а в том, **чего больше нет** — оболочки, `npm`, `yarn`, их пакетов и дыр в них (в шаге 5.5 сканер это подтвердит).

Сделаем этот Dockerfile основным, а прежний — запасным для отладки (в нём можно зайти внутрь через `sh`):

```bash run
cd ~/docker-lab/coffeeshop/api
mv Dockerfile Dockerfile.alpine
mv Dockerfile.distroless Dockerfile
ls
```

```out auto
```

### why
Multi-stage — главный инструмент оптимизации Docker-образов. Он разделяет «как собрать» и «что запускать»: сборочные инструменты не едут на сервер, итоговый образ меньше, быстрее и безопаснее. Для Node-приложений с TypeScript или сборкой фронтенда выигрыш в сотни мегабайт; в шаге 5.6 увидишь это на настоящем примере.

### deep Команда по частям
`COPY --from=deps /app/node_modules ./node_modules`: `--from=deps` — брать файлы не из контекста сборки, а из этапа с именем `deps` (можно и по номеру, `--from=0`); `/app/node_modules` — путь внутри этапа; `./node_modules` — куда положить в текущем этапе. `docker build --target deps .` соберёт только до этапа `deps` (удобно для отладки сборочного этапа).

### deep Как ещё можно
- **Без distroless, но с multi-stage:** итоговый этап `FROM node:24-alpine` и `COPY --from=deps` — меньше, чем кажется, но всё равно чище, чем ставить всё в итоговом образе.
- **Отладка distroless:** `docker debug slim` (команда Docker Desktop) подключает к контейнеру отладочную оболочку; либо запускай запасной образ `coffee-api:alpine`.
- **Запасной Dockerfile для разработки:** `docker build -f Dockerfile.alpine -t coffee-api:alpine .`.

### deep Если не получилось
- **`COPY --from=deps: invalid from flag value deps`** — имя этапа в `AS` и в `--from` не совпадает (регистр, опечатка).
- **`Cannot find module 'express'`** — забыла скопировать `node_modules` из этапа `deps`, или рабочая папка не `/app`.
- **`exec: "sh": executable file not found`** — всё правильно: в distroless нет оболочки; смотри логи (`docker logs`) или `docker debug`.
- **`MODULE_NOT_FOUND ... server.js`** — в `CMD` указано имя файла, которого нет в итоговом этапе: проверь `COPY package.json server.js ./`.

### quiz
- Что попадает в итоговый образ при нескольких `FROM`?
- Что делает `COPY --from=deps` и чем он отличается от обычного `COPY`?
- Какие преимущества у distroless-образа и какое неудобство?

### links
- https://docs.docker.com/build/building/multi-stage/ | multi-stage сборки | Multi-stage builds
- https://github.com/GoogleContainerTools/distroless | distroless | distroless

## 5.3 BuildKit: кэш-монтирование, секреты, buildx | short: BuildKit и buildx | est: ~40 мин
### intro
**Слова шага:** *BuildKit*, *`RUN --mount=type=cache`*, *`RUN --mount=type=secret`*, *`buildx`*, *мультиплатформенная сборка*.

:::tip Если совсем просто
BuildKit — «умный повар» внутри Docker: умеет готовить несколько блюд сразу, ничего не готовит зря и умеет держать **общую кладовку** для всех сборок (кэш) и **сейф**, из которого нельзя ничего вынести в готовое блюдо (секрет).
:::

**BuildKit** — современный движок сборки; он включён по умолчанию (ты уже видела его вывод `#5 [1/3] …`). Команда **`docker buildx`** — расширенный интерфейс к нему. Три приёма, которые стоит знать.

**1. Кэш-монтирование.** Обычный слой с `npm ci` при изменении `package.json` скачивает все пакеты заново. С `--mount=type=cache` папка кэша **живёт между сборками** и в образ не попадает. Покажем сам механизм на понятном примере: в «кэш» каждый раз кладём новый файл и считаем, сколько там файлов. Сборку запускаем два раза с разным `--build-arg BUMP` (аргумент входит в команду, поэтому слой пересобирается заново), а кэш `demo5` (его имя — `id`) сохраняется между сборками:

```bash run
mkdir -p ~/docker-lab/s05/cache && cd ~/docker-lab/s05/cache
cat > Dockerfile <<'EOF'
FROM alpine:3.22
ARG BUMP=0
RUN --mount=type=cache,id=demo5,target=/cache echo "сборка $BUMP" > /dev/null; touch /cache/file-$(date +%s%N); echo "файлов в кэше: $(ls /cache | wc -l)"
EOF
docker build --progress=plain --build-arg BUMP=1 -t cache:1 . 2>&1 | grep 'файлов в кэше:'
docker build --progress=plain --build-arg BUMP=2 -t cache:2 . 2>&1 | grep 'файлов в кэше:'
docker run --rm cache:2 ls /cache
```

### result
```out auto
```

Первая сборка положила в пустой кэш один файл (`1`); вторая, хотя слой пересобирался, нашла там прежний файл и добавила второй (`2`) — кэш пережил обе сборки. В **готовый образ** кэш не попадает: последняя команда сообщает, что папки `/cache` в образе нет. Для настоящего проекта папка кэша — та, куда пакетный менеджер складывает скачанное: `RUN --mount=type=cache,target=/root/.npm npm ci`. Тогда при изменении `package.json` скачиваются только новые пакеты, а остальные берутся с диска. На маленьком проекте выигрыш в секунды, на большом — в минуты и мегабайты трафика.

**2. Секреты сборки.** Иногда на этапе сборки нужен пароль (токен приватного npm-реестра). Положить его в `ENV` или `ARG` нельзя (шаг 4.2) — он останется в слоях. `--mount=type=secret` даёт секрет **только на время одной команды**, не записывая в образ:

```bash run
cd ~/docker-lab/s05/cache
printf 'S3CR3T-TOKEN-12345' > token.txt
cat > Dockerfile.secret <<'EOF'
FROM alpine:3.22
RUN --mount=type=secret,id=npmtoken sh -c 'echo "секрет доступен, длина: $(wc -c < /run/secrets/npmtoken)"'
EOF
docker build --progress=plain --secret id=npmtoken,src=token.txt -f Dockerfile.secret -t secret:1 . 2>&1 | grep 'секрет доступен'
echo "--- ищем секрет в истории образа:"
docker history --no-trunc secret:1 | grep -c 'S3CR3T' || true
echo "--- есть ли файл секрета в готовом образе:"
docker run --rm secret:1 ls /run/secrets
```

```out auto
```

Команда видела секрет (длина 18 символов — это `S3CR3T-TOKEN-12345`), но в истории образа его **нет** (счётчик `0`), и в готовом образе папки `/run/secrets` не существует. Так передают токены для приватных пакетов.

**3. `buildx` и несколько платформ.** `docker buildx ls` показывает «сборщики» (builders), `docker buildx build --platform linux/amd64,linux/arm64 …` собирает образ сразу под несколько архитектур — нужно, когда ты на Mac с ARM, а сервер на `amd64`:

```bash run
docker buildx ls
```

```out auto
```

:::trap Не проверено запуском
Сборку под несколько платформ сразу (`--platform linux/amd64,linux/arm64`) мы не запускали в тестовой среде: она требует эмуляции чужого процессора (QEMU) и заметно греет компьютер. Попробуй сама на своём Mac: `docker buildx build --platform linux/amd64 -t coffee-api:amd64 .` (сборка под `amd64` на ARM-Mac пойдёт через эмуляцию, будет медленнее). Проверить результат можно `docker image inspect --format '{{.Architecture}}' coffee-api:amd64`.
:::

### why
Кэш-монтирование ускоряет повседневные сборки, секреты исключают утечки паролей в образы, а `buildx` нужен, как только сборка и запуск происходят на машинах с разными процессорами. Всё это — всего по одной строке в Dockerfile, но они отличают «учебный» образ от «рабочего».

### deep Команда по частям
`RUN --mount=type=cache,id=demo5,target=/cache …`: `--mount=type=cache` — подключить постоянную папку-кэш; `id=demo5` — её имя (у разных проектов имена разные); `target=/cache` — где она появится внутри `RUN` (для настоящего проекта — папка кэша пакетного менеджера, у `npm` это `/root/.npm`). `docker build --secret id=npmtoken,src=token.txt` — передать файл `token.txt` как секрет с именем `npmtoken`; внутри он лежит в `/run/secrets/npmtoken`.

### deep Если не получилось
- **`unknown flag: --mount`** — отключён BuildKit (старый Docker): обнови Docker Desktop.
- **Секрет «не найден» (`No such file`)** — `id` в `--secret` и в `--mount=type=secret,id=` должны совпадать.
- **Кэш не ускорил** — `target` указывает не туда, где пакетный менеджер хранит кэш (для `npm` — `/root/.npm`, для `pip` — `/root/.cache/pip`, для `apt` — `/var/cache/apt`).

### quiz
- Чем кэш-монтирование отличается от обычного слоя-кэша?
- Почему секрет нельзя передавать через `ARG` и как его передают правильно?
- Зачем нужна мультиплатформенная сборка?

### links
- https://docs.docker.com/build/cache/optimize/ | оптимизация кэша | Optimize cache
- https://docs.docker.com/build/building/secrets/ | секреты сборки | Build secrets
- https://docs.docker.com/build/building/multi-platform/ | мультиплатформенные сборки | Multi-platform builds

## 5.4 Безопасность контейнера: non-root, read-only, capabilities | short: Безопасность запуска | est: ~40 мин
### intro
**Слова шага:** *non-root*, *`--read-only`*, *`--tmpfs`*, *capabilities*, *`--cap-drop`*, *`no-new-privileges`*, *лимиты ресурсов*.

:::tip Если совсем просто
Представь, что контейнер — это сотрудник в офисе. Не давай ему ключи от всех кабинетов: пусть работает **обычным сотрудником** (не root), без права что-то переставлять в здании (`read-only`), с минимумом пропусков (`cap-drop`) и в рамках бюджета (лимиты памяти и процессов). Если сотрудника «обманут», навредить он сможет мало.
:::

Принцип **наименьших привилегий**: контейнеру даётся ровно то, что нужно. Четыре рычага:

- **Не root.** Мы уже сделали это (`USER node` / `USER nonroot`).
- **`--read-only`** — файловая система контейнера только для чтения; писать можно только в явно разрешённые места (`--tmpfs /tmp` — временная папка в памяти).
- **Capabilities (возможности).** Всемогущий root в Linux разбит на ~40 отдельных «прав» (менять владельца файлов, открывать порты < 1024, менять время…). `--cap-drop ALL` убирает все, `--cap-add` добавляет нужные.
- **`--security-opt no-new-privileges`** — запрещает процессу повышать привилегии (через `setuid`-программы).

И лимиты: `--memory 128m` (потолок памяти, cgroup, шаг 1.2), `--pids-limit 100` (не более 100 процессов — защита от «форк-бомб»), `--cpus 0.5`.

Запустим наш distroless-API со всеми настройками и проверим, что он работает:

```bash run
docker run -d --name hard -p 3011:3000 --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges --memory 128m --pids-limit 100 --cpus 0.5 coffee-api:slim
sleep 2
curl -s -w '\n' http://localhost:3011/health
docker inspect --format 'read-only={{.HostConfig.ReadonlyRootfs}} cap-drop={{.HostConfig.CapDrop}} memory={{.HostConfig.Memory}} pids={{.HostConfig.PidsLimit}}' hard
```

### result
```out auto
```

Приложение работает со всеми ограничениями (ему они не мешают, потому что оно ничего не пишет на диск и не требует особых прав). Теперь покажем, что ограничения работают, на «подопытном» Alpine-образе с оболочкой: попробуем записать файл и сменить владельца:

```bash run
docker run --rm --read-only alpine:3.22 sh -c 'touch /file.txt'
docker run --rm --read-only --tmpfs /tmp alpine:3.22 sh -c 'touch /tmp/file.txt && echo "в /tmp писать можно"'
docker run --rm alpine:3.22 sh -c 'chown nobody /tmp && echo "root может менять владельца"'
docker run --rm --cap-drop ALL alpine:3.22 sh -c 'chown nobody /tmp'
```

```out auto
```

Читай по порядку: **1)** `--read-only` — запись в корень запрещена (`Read-only file system`); **2)** но в `--tmpfs /tmp` писать можно; **3)** обычный root в контейнере может `chown`; **4)** с `--cap-drop ALL` тот же `chown` даёт `Operation not permitted` — нужного права (`CAP_CHOWN`) у процесса больше нет. Уберём контейнер:

```bash run
docker rm -f hard
```

```out auto
```

### why
Контейнер — не волшебная защита: он изолирован, но использует общее ядро, и неудачно настроенный контейнер — риск для всего хоста. Эти флаги почти бесплатны и сильно сужают то, что способен сделать атакующий, добравшийся до контейнера. В Compose (сессия 9) они задаются теми же строками в `compose.yaml`, а в Kubernetes — через `securityContext`.

### deep Команда по частям
`docker run … --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges --memory 128m --pids-limit 100 --cpus 0.5 …`: файловая система только чтение; временная память-папка `/tmp`; убрать все capabilities; запретить повышение прав; потолок 128 МБ; не больше 100 процессов; не больше полпроцессора. Если приложению нужно слушать порт ниже 1024, добавь `--cap-add NET_BIND_SERVICE`.

### deep Как ещё можно
- **Rootless Docker:** сам демон может работать не от root — безопаснее, но настройка сложнее (для Linux-серверов).
- **Профили seccomp и AppArmor:** Docker уже применяет профиль по умолчанию, запрещающий опасные системные вызовы.
- **Не монтируй `/var/run/docker.sock`** внутрь контейнера без крайней необходимости: кто управляет этим сокетом, тот управляет всем Docker.
- **`--privileged`** — выключает почти все ограничения; в прикладных контейнерах его быть не должно.

### deep Если не получилось
- **Приложение падает с `Read-only file system`** — оно пишет в папку, которая не вынесена в `--tmpfs` или том; найди путь в сообщении об ошибке.
- **`operation not permitted` при старте** — убрали capability, которая приложению нужна; добавляй по одной (`--cap-add`).
- **`out of memory` / код 137** — лимит `--memory` слишком мал.

### quiz
- Зачем нужен `--read-only` и как разрешить приложению писать во временную папку?
- Что такое capabilities и что делает `--cap-drop ALL`?
- Для чего лимиты `--memory` и `--pids-limit`?

### links
- https://docs.docker.com/engine/security/ | безопасность Docker | Docker security
- https://docs.docker.com/engine/containers/resource_constraints/ | ограничение ресурсов | Resource constraints

## 5.5 Сканирование образов на уязвимости | short: Сканер уязвимостей | est: ~35 мин
### intro
**Слова шага:** *уязвимость*, *CVE*, *severity (HIGH/CRITICAL)*, *SBOM*, *Trivy*, *`docker scout`*.

:::tip Если совсем просто
Сканер — как санитарный инспектор: заходит на кухню и читает на каждой банке состав. Если в какой-то банке нашли «просроченный продукт» (пакет с известной дырой), он пишет протокол: что, где и чем заменить.
:::

**Уязвимость (CVE)** — известная ошибка безопасности в конкретной версии пакета; у неё есть номер (`CVE-2026-…`) и важность: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`. **Сканер** читает список пакетов внутри образа (его называют **SBOM** — перечень компонентов), сверяет с базой известных уязвимостей и выдаёт отчёт. Популярные сканеры: **Trivy** (бесплатный, ставится одной командой), **Docker Scout** (встроен в Docker Desktop и `docker scout`, требует входа в аккаунт), Grype, Snyk.

Запустим Trivy как контейнер (так не нужно ничего ставить). `-v /var/run/docker.sock:…` даёт Trivy доступ к демону, чтобы он прочитал локальные образы; `--severity HIGH,CRITICAL` оставляет только серьёзное. Сначала старый Alpine-образ с `npm` и `yarn`:

```bash run
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --quiet coffee-api:2 | grep -E 'Report Summary|Total'
```

### result
```out auto
```

Строка `Total: N (HIGH: N, CRITICAL: N)` — итог: найдено столько-то серьёзных уязвимостей. Откуда они? Развернём отчёт и посмотрим, **в каких пакетах** (первая колонка таблицы):

```bash run
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --quiet --format json coffee-api:2 | jq -r '.Results[] | .Vulnerabilities[]? | .PkgName' | sort | uniq -c | sort -rn
```

```out auto
```

Все находки — внутри пакетов самого `npm` (`brace-expansion`, `undici`, `tar`, `ip-address`, `http-cache-semantics`): они лежат в `/usr/local/lib/node_modules/npm`, который приехал вместе с образом `node`. Нашему приложению `npm` в работе не нужен — он нужен только при сборке. Теперь тот же отчёт для distroless-образа из шага 5.2:

```bash run
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL --quiet coffee-api:slim | grep 'Total' || echo "серьёзных уязвимостей не найдено"
```

```out auto
```

Серьёзных находок нет (строки `Total` в отчёте не появилось): `npm` и `yarn` в итоговый образ просто не попали. Это и есть практический смысл multi-stage и distroless (шаг 5.2): выбросить из образа всё, что не нужно для работы.

Как читать отчёт, если находки есть: в таблице видна **строка пакета**, **версия установленная** и **версия с исправлением** (`Fixed Version`). Алгоритм: обнови базовый образ (`docker pull node:24-alpine` и пересобери) — часто исправление уже выпущено; если нет — оцени, достижима ли уязвимость в твоём приложении, и либо убери пакет из образа, либо запиши причину, по которой риск принят.

### why
Образ — это набор чужого кода, а в чужом коде регулярно находят дыры. Сканирование в CI (сессия 10) и привычка проверять образ перед выкладкой не заставляют образ быть идеальным, но не дают выкатить явную проблему незаметно. А вместе с multi-stage — делают образ чище.

### deep Как ещё можно
- **Docker Scout:** `docker scout quickview coffee-api:slim` (нужен `docker login`); результаты видны и во вкладке *Images* в Docker Desktop.
- **Сканировать до сборки образа:** `trivy fs .` проверяет зависимости проекта по файлам `package-lock.json`.
- **Падать, если есть серьёзное:** `trivy image --exit-code 1 --severity CRITICAL образ` — ненулевой код выхода остановит конвейер CI.
- **Сохранить SBOM:** `docker buildx build --sbom=true …` кладёт перечень пакетов вместе с образом.

### deep Если не получилось
- **Долго «скачивает базу»** — при первом запуске Trivy загружает свою базу уязвимостей (десятки мегабайт), потом она кэшируется.
- **`Cannot connect to the Docker daemon` внутри Trivy** — не смонтирован сокет `-v /var/run/docker.sock:/var/run/docker.sock`.
- **Находки есть, а исправлений нет** — бывает: отметь как принятый риск или ищи другой базовый образ.

### quiz
- Что такое CVE и что показывают уровни HIGH и CRITICAL?
- Почему уязвимости были в `npm`, а не в нашем коде, и как multi-stage помог?
- Что делать, если сканер нашёл уязвимость с исправленной версией?

### links
- https://trivy.dev/ | сканер Trivy | Trivy
- https://docs.docker.com/scout/ | Docker Scout | Docker Scout

## 5.6 Контейнеризируем frontend: nginx и multi-stage | short: Frontend на nginx | est: ~50 мин
### intro
**Слова шага:** *статика*, *сборка фронтенда*, *`esbuild`*, *nginx*, *multi-stage*, *`--target`*.

:::tip Если совсем просто
Сайт — это страничка, которую нужно просто «раздать» людям; раздачей занимается швейцар **nginx**. Но чтобы страничка получилась, её сначала «собирают» на кухне с кучей инструментов. На кухне инструменты нужны, а на витрине — нет. Поэтому: собираем в одном контейнере, а на витрину (в итоговый образ nginx) переносим только готовую страницу.
:::

Второй сервис CoffeeShop — **сайт**: страница, которая показывает меню. Он состоит из `index.html` и скрипта `app.js`; скрипт мы «собираем» (склеиваем и сжимаем) утилитой **esbuild** — это настоящий этап сборки фронтенда. Именно для таких задач и придуман multi-stage: Node и esbuild нужны только для сборки, а в итоговый образ входит один nginx со статикой.

Создадим файлы. `package.json` описывает единственную зависимость для сборки (`esbuild`), в `src/app.js` — логика страницы:

```bash run
mkdir -p ~/docker-lab/coffeeshop/web/src && cd ~/docker-lab/coffeeshop/web
cat > package.json <<'EOF'
{
  "name": "coffeeshop-web",
  "version": "1.0.0",
  "private": true,
  "scripts": { "build": "esbuild src/app.js --bundle --minify --outfile=dist/app.js" },
  "devDependencies": { "esbuild": "^0.25.0" }
}
EOF
cat > index.html <<'EOF'
<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <title>CoffeeShop</title>
</head>
<body>
  <h1>☕ CoffeeShop</h1>
  <p id="status">Загружаю меню…</p>
  <ul id="menu"></ul>
  <script src="/app.js"></script>
</body>
</html>
EOF
cat > src/app.js <<'EOF'
const status = document.getElementById('status')
const list = document.getElementById('menu')

async function loadMenu() {
  try {
    const res = await fetch('/api/menu')
    const menu = await res.json()
    status.textContent = 'Меню на сегодня:'
    list.innerHTML = menu.map((d) => `<li>${d.name} — ${d.price} ₽</li>`).join('')
  } catch (e) {
    status.textContent = 'Меню пока недоступно: API не подключён.'
  }
}

loadMenu()
EOF
docker run --rm -v "$PWD":/app -w /app node:24-alpine npm install --package-lock-only --no-fund --no-audit --loglevel=error 2>&1 | grep -v notice
ls
```

### result
```out auto
```

Теперь Dockerfile из двух этапов и `.dockerignore`. Этап `build` ставит `esbuild` и собирает `dist/app.js`; итоговый этап — `nginx:1.30-alpine` — получает только `index.html` и собранный скрипт:

```bash run
cd ~/docker-lab/coffeeshop/web
cat > Dockerfile <<'EOF'
FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY src ./src
RUN npm run build

FROM nginx:1.30-alpine
COPY index.html /usr/share/nginx/html/index.html
COPY --from=build /app/dist/app.js /usr/share/nginx/html/app.js
EXPOSE 80
EOF
printf 'node_modules\ndist\n.git\n*.log\n.env\nDockerfile\n.dockerignore\n' > .dockerignore
docker build -q -t coffee-web:1 .
docker build -q --target build -t coffee-web:build . > /dev/null
docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}' | grep -E 'REPOSITORY|coffee-web'
```

```out auto
```

Сравни два образа: `coffee-web:build` — это этап сборки (Node, `esbuild`, все `node_modules`, сотни мегабайт), `coffee-web:1` — итоговый образ с nginx. Флаг `--target build` остановил сборку на этапе `build` — так мы взглянули на «кухню». Итоговый образ существенно меньше: в нём нет ни Node, ни `npm`, ни исходников. Запускаем и проверяем:

```bash run
docker run -d --name web -p 8080:80 coffee-web:1
sleep 2
curl -s -o /dev/null -w 'index.html: %{http_code}\n' http://localhost:8080/
curl -s -o /dev/null -w 'app.js: %{http_code}\n' http://localhost:8080/app.js
curl -s http://localhost:8080/ | grep '<h1>'
docker exec web ls /usr/share/nginx/html
docker rm -f web
```

```out auto
```

Страница и скрипт раздаются, а внутри — только готовые файлы. Меню сайт пока не покажет: адрес `/api/menu` ни к чему не подключён — этим займётся сессия 6 (сети) и сессия 8 (Compose).

### why
Сборка фронтенда — самый наглядный случай, где multi-stage нужен по-настоящему: сборочный образ весит в разы больше итогового, а в итоговый образ попадают только статические файлы. Тот же приём работает для TypeScript-бэкенда, Go, Java и всего, что сначала компилируется.

### deep Команда по частям
`docker build -q --target build -t coffee-web:build .`: `--target build` — собрать только до этапа с именем `build`; `-t coffee-web:build` — дать образу имя, чтобы потом его можно было сравнить. Без `--target` Docker собирает весь файл и тегирует **последний** этап.

### deep Как ещё можно
- **Готовый «непривилегированный» nginx:** `nginxinc/nginx-unprivileged:1.30-alpine` — работает не от root и слушает порт 8080 (в шаге 5.7 сделаем похожее вручную).
- **Другие сборщики:** Vite, webpack — используются так же: этап `build` собирает, итоговый этап раздаёт.
- **Кэш `npm`:** добавь в этап `build` `RUN --mount=type=cache,target=/root/.npm npm ci` (шаг 5.3).

### deep Если не получилось
- **`npm ci` падает с `package-lock.json not found`** — сначала нужен lock-файл: выполни команду `npm install --package-lock-only` из шага.
- **Страница пустая или `404` на `/app.js`** — не скопирован собранный файл из этапа `build`: проверь `COPY --from=build`.
- **`esbuild: not found`** — в этапе `build` выполнен `npm ci --omit=dev`; для сборки нужны devDependencies, поэтому там просто `npm ci`.

### quiz
- Какие два этапа в Dockerfile сайта и что делает каждый?
- Почему итоговый образ сайта намного меньше сборочного?
- Что делает `--target build` и зачем он нужен?

### links
- https://hub.docker.com/_/nginx | образ nginx | nginx
- https://esbuild.github.io/ | esbuild | esbuild

## 5.7 🔨 Сломать → починить: после non-root — permission denied | short: permission denied | est: ~30 мин
### intro
**Слова шага:** *права на файлы*, *владелец*, *`COPY --chown`*, *`chown`*, *`permission denied`*.

:::tip Если совсем просто
Ты перевела сотрудника из директоров в обычные работники — а все ящики в офисе остались «только для директора». Теперь он не может открыть ни один и жалуется: «Не пускают!». Решение — выдать ему ключи от нужных ящиков (сменить владельца), а не возвращать в директоры.
:::

Частая ситуация: приложение работало, ты добавила `USER node` — и оно стало падать с `permission denied`. Причина: файлы и папки создал **root** (при сборке до `USER`), а процесс теперь работает от обычного пользователя и не может в них писать. Воспроизведём на Alpine-варианте нашего API (в нём есть оболочка). Допустим, приложению нужна папка `/app/data` для записи (журнал заказов):

```bash run
cd ~/docker-lab/coffeeshop/api
cat > Dockerfile.perm <<'EOF'
FROM node:24-alpine
WORKDIR /app
RUN mkdir -p /app/data
USER node
CMD ["sh", "-c", "touch /app/data/orders.log && echo 'журнал создан'"]
EOF
docker build -q -f Dockerfile.perm -t perm:1 . > /dev/null
docker run --rm perm:1
docker run --rm --entrypoint sh perm:1 -c 'ls -ld /app/data; id -un'
```

### result
```out auto
```

Читай справа налево: `Permission denied` — доступ закрыт; путь `/app/data/orders.log`. Диагностика — во втором запуске: папка `/app/data` принадлежит `root root` (создана инструкцией `RUN mkdir` до `USER`), а процесс идёт от пользователя `node`. У `node` в чужой папке прав на запись нет. **Починка:** выдать папку тому, кто будет в неё писать. Это делают `chown` при создании папки или `COPY --chown`:

```bash run
cd ~/docker-lab/coffeeshop/api
cat > Dockerfile.perm <<'EOF'
FROM node:24-alpine
WORKDIR /app
RUN mkdir -p /app/data && chown node:node /app/data
USER node
CMD ["sh", "-c", "touch /app/data/orders.log && echo 'журнал создан'"]
EOF
docker build -q -f Dockerfile.perm -t perm:2 . > /dev/null
docker run --rm perm:2
docker run --rm --entrypoint sh perm:2 -c 'ls -ld /app/data'
```

```out auto
```

Теперь владелец папки — `node`, и запись проходит. Чаще всего правки такие: **`RUN chown node:node папка`** для созданных папок или **`COPY --chown=node:node файлы ./`** для копируемых файлов; и ставить `USER` **после** этих инструкций. Уберём за собой:

```bash run
cd ~/docker-lab/coffeeshop/api
docker rmi perm:1 perm:2 > /dev/null
rm -f Dockerfile.perm
docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}' | grep -E 'REPOSITORY|coffee|perm'
```

```out auto
```

### why
`permission denied` после перехода на не-root — самая частая цена за безопасность. Правило, которое надо помнить: **кто создал файл, тот и владелец, а `USER` определяет, кем работаешь после**. Не возвращайся в root «чтобы заработало» — исправь владельца: безопасность важнее минуты возни.

### deep Если не получилось
- **Ошибка в томе (`volume`) при запуске** — права тома задаются при его создании; в сессии 7 разберём, как том наследует владельца.
- **`chown: unknown user/group node`** — в образе нет такого пользователя (в `alpine` базе без Node его нет): создай `RUN adduser -D -u 1000 app` или используй образ, где пользователь есть.
- **Хочется «просто разрешить всем»** — `chmod 777` работает, но открывает папку любому процессу в контейнере; лучше точный `chown`.

### quiz
- Почему после `USER node` приложение не может писать в папку, созданную раньше?
- Как исправить: сменить владельца или вернуть root? Почему?
- Что делает `COPY --chown=node:node`?

### outro
:::tip Приёмка сессии 5
- Ты измерила образ (размер, время сборки, уязвимости) и записала цифры «до/после».
- API собран через multi-stage на distroless: нет оболочки, нет `npm`, процесс идёт от `nonroot`, останавливается мгновенно.
- Сайт собран двумя этапами: итоговый образ — nginx со статикой, без Node.
- Ты умеешь запускать контейнер с `--read-only`, `--tmpfs`, `--cap-drop ALL`, лимитами памяти и процессов и объяснить каждый флаг.
- Trivy на `coffee-api:slim` не находит серьёзных уязвимостей, а на старом образе находит — и ты знаешь, почему.
- Ты умеешь передать секрет сборки через `--mount=type=secret`, и он не попадает в образ.
- Ты исправляешь `permission denied` сменой владельца, а не возвратом в root.
:::
