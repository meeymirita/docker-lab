# Сессия 10 · Registry, GHCR, CI
dur: ~4 ч

## 10.1 Устройство registry: манифест, слои, push и pull | short: Устройство registry | est: ~40 мин
### intro
**Слова шага:** *registry*, *репозиторий*, *тег*, *манифест*, *слой (blob)*, *digest*, *`docker push` / `docker pull`*.

:::tip Если совсем просто
Registry — это **склад коробок** (образов). У каждой коробки есть **этикетка-тег** (`1.0.0`) и **опись содержимого** (манифест): «внутри такие-то слои». `docker push` — отнести коробку на склад, `docker pull` — забрать. Склад не хранит дубли: если слой уже лежит, повторно его не принимают.
:::

```svg
<svg viewBox="0 0 640 250" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Registry: push и pull" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m1-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m1-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><rect x="10" y="85" width="130" height="60" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="75.0" y="111.0" text-anchor="middle" font-size="13" fill="currentColor">Твой Docker</text><text x="75.0" y="129.0" text-anchor="middle" font-size="13" fill="currentColor">(Mac)</text><rect x="500" y="20" width="130" height="215" rx="8" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="565" y="14" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor" fill-opacity="1">Registry</text><rect x="512" y="36" width="106" height="42" rx="8" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.5"/><text x="565.0" y="53.0" text-anchor="middle" font-size="11" fill="currentColor">manifest</text><text x="565.0" y="71.0" text-anchor="middle" font-size="11" fill="currentColor">(список слоёв)</text><rect x="512" y="90" width="106" height="36" rx="8" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-width="1.5"/><text x="565.0" y="113.0" text-anchor="middle" font-size="12" fill="currentColor">слой 1</text><rect x="512" y="132" width="106" height="36" rx="8" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-width="1.5"/><text x="565.0" y="155.0" text-anchor="middle" font-size="12" fill="currentColor">слой 2</text><rect x="512" y="174" width="106" height="36" rx="8" fill="currentColor" fill-opacity="0.06" stroke="currentColor" stroke-width="1.5"/><text x="565.0" y="197.0" text-anchor="middle" font-size="12" fill="currentColor">config</text><line x1="140" y1="105" x2="500" y2="60" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)"/><text x="320.0" y="75.5" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">docker push</text><line x1="500" y1="130" x2="140" y2="130" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)"/><text x="320.0" y="123.0" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">docker pull</text><text x="320" y="235" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor" fill-opacity="1">тег  →  manifest  →  слои (blobs) по хэшам</text></svg>
```

**Registry** — сервер, хранящий образы (Docker Hub, GitHub Container Registry, Quay, облачные реестры, свой на своём сервере). Устройство одинаково для всех и построено на **HTTP-API**:

- **Репозиторий** — набор версий одного образа (`coffee-api`).
- **Тег** — читаемое имя версии (`1.0.0`, `latest`). Тег — **указатель**, его можно переставить.
- **Манифест** — небольшой JSON-документ: из каких слоёв состоит образ и какой у него конфиг. Именно манифест адресуется тегом.
- **Слои и конфиг (blobs)** — тяжёлые данные, каждое хранится под своим **digest** (хэш содержимого, шаг 3.1).

`docker pull имя:тег` делает три шага: **1)** запросить манифест по тегу; **2)** увидеть список слоёв и **скачать только те, которых ещё нет локально** (`Already exists`); **3)** собрать образ из слоёв. `docker push` — обратное: слои, которых на складе нет, загружаются, потом отправляется манифест.

Поднимем **собственный registry** — это обычный контейнер из образа `registry:2`. Порт 5000 на Mac часто занят системной службой AirPlay, поэтому публикуем **5050**; том `registry-data` хранит образы (шаг 7.2):

```bash run
docker run -d --name registry -p 5050:5000 -v registry-data:/var/lib/registry registry:2
sleep 2
docker tag coffee-api:slim localhost:5050/coffee-api:1.0.0
docker push localhost:5050/coffee-api:1.0.0
```

### result
```out auto
```

`docker tag … localhost:5050/coffee-api:1.0.0` дал образу **полное имя** с адресом нашего registry (формат `адрес/репозиторий:тег`, шаг 3.2). `docker push` отправил слои (`Pushed`) и манифест — в последней строке его digest. Спросим у registry напрямую через HTTP-API (`curl`): какие репозитории и теги у него есть:

```bash run
curl -s http://localhost:5050/v2/_catalog
curl -s http://localhost:5050/v2/coffee-api/tags/list
```

```out auto
```

Теперь посмотрим сам **манифест**. Образ, собранный современным Docker, лежит как *индекс* — список платформ (`arm64` у образа и служебная запись об аттестации), а у каждой платформы — свой манифест со слоями. Достанем слои (ключи в `jq` пишем латиницей — кириллические имена полей он не принимает):

```bash run
ACC='application/vnd.oci.image.index.v1+json, application/vnd.oci.image.manifest.v1+json'
curl -s -H "Accept: $ACC" http://localhost:5050/v2/coffee-api/manifests/1.0.0 | jq -c '{type: .mediaType, platforms: [.manifests[].platform.architecture]}'
D=$(curl -s -H "Accept: $ACC" http://localhost:5050/v2/coffee-api/manifests/1.0.0 | jq -r '.manifests[0].digest')
curl -s -H "Accept: $ACC" "http://localhost:5050/v2/coffee-api/manifests/$D" | jq -c '{config: .config.digest[0:19], layers_count: (.layers|length), layers: [.layers[].digest[0:19]]}'
```

```out auto
```

Видна вся цепочка: тег → индекс (`oci.image.index`) → манифест платформы → конфиг и слои по хэшам. Слои — те же самые, что ты видела в `docker history` (шаг 3.1): registry хранит их по digest, поэтому одинаковые слои у разных образов лежат один раз.

### why
Понимание, что registry — это просто «HTTP-сервер с манифестами и слоями», снимает магию: `pull`, `push`, GHCR, Docker Hub и закрытый реестр компании работают одинаково, отличаются адресом и правами. Это основа для следующих шагов — публикации в GHCR и сборки в CI.

### deep Команда по частям
`docker run -d --name registry -p 5050:5000 -v registry-data:/var/lib/registry registry:2`: образ `registry:2` слушает порт 5000 и хранит данные в `/var/lib/registry`; мы публикуем его как 5050 и подключаем именованный том, чтобы образы переживали пересоздание контейнера. `curl -s http://localhost:5050/v2/_catalog` — стандартный вызов HTTP-API Docker Registry: список репозиториев. `jq -c` — компактный JSON-вывод, `[0:19]` — первые 19 символов digest.

### deep Как ещё можно
- **Посмотреть манифест без `curl`:** `docker buildx imagetools inspect localhost:5050/coffee-api:1.0.0`.
- **Образ с веб-интерфейсом:** кроме `registry:2` есть Harbor, Gitea/Forgejo, GitLab Registry — те же API и больше возможностей (права, сканирование).
- **Docker Hub, GHCR, Quay** — публичные реестры; облачные (ECR, GCR, ACR) — у провайдеров.

### deep Если не получилось
- **`port is already allocated` на 5000** — это AirPlay на Mac; мы уже взяли 5050.
- **`connection refused` при `push`** — `registry` ещё не запустился: подожди секунду, `docker ps`.
- **`jq: command not found`** — на Mac `brew install jq` (в методичке команда выполнена в контейнере с `jq`).

### quiz
- Что такое манифест и чем он отличается от слоя?
- Какие три шага делает `docker pull`?
- Почему при `docker push` второго образа на том же базовом слое этот слой не загружается повторно?

### links
- https://distribution.github.io/distribution/ | Docker Registry (distribution) | Distribution registry
- https://docs.docker.com/reference/cli/docker/image/push/ | docker push | docker image push

## 10.2 Свой registry: push, pull «с чистой машины», небезопасные адреса | short: Свой registry | est: ~35 мин
### intro
**Слова шага:** *`localhost:5050`*, *«чистая машина»*, *insecure registry*, *TLS*, *`insecure-registries`*.

:::tip Если совсем просто
Склад работает. Проверим главное: если я **выброшу коробку из своего дома** и заберу её со склада — получится ли та же самая? Заодно узнаем, почему на «чужой» склад по обычному адресу пускают не сразу: нужен замок (**HTTPS**).
:::

Проверим «жизненный цикл» образа, как это бывает при выкладке: на сервере **нет** твоего образа, есть только registry. Удалим образ локально (оба имени) и скачаем его заново:

```bash run
docker rmi coffee-api:slim localhost:5050/coffee-api:1.0.0
docker images --format '{{.Repository}}:{{.Tag}}' | grep -c '^coffee-api:slim$' || true
docker pull localhost:5050/coffee-api:1.0.0
docker tag localhost:5050/coffee-api:1.0.0 coffee-api:slim
docker run --rm -d --name from-registry -p 3050:3000 -e DB_HOST=nowhere localhost:5050/coffee-api:1.0.0 > /dev/null
sleep 2
docker logs from-registry 2>&1 | head -2
docker rm -f from-registry > /dev/null 2>&1
```

### result
```out auto
```

Локальных имён не осталось (счётчик `0`), и `docker pull` обратился к нашему registry: запросил манифест, проверил слои и забрал недостающие. Почти у всех слоёв стоит `Already exists` — Docker, как и положено, держит слои в своём хранилище на диске, пока их не вычистит сборка мусора, и повторно не качает; два слоя скачались заново (`Pull complete`). На настоящей чистой машине (новый сервер) будут `Pull complete` у каждого слоя. Образ ожил — приложение стартует и сообщает, что не нашло базу (мы нарочно указали несуществующий `DB_HOST`): значит, образ «приехал» целиком. Увидеть полную загрузку на пустой машине ты сможешь в шаге 10.3 (пункт 6). Вернули привычное имя `coffee-api:slim` командой `docker tag`.

**Данные registry живут в томе.** Пересоздадим сам registry и убедимся, что образы не пропали:

```bash run
docker rm -f registry
docker run -d --name registry -p 5050:5000 -v registry-data:/var/lib/registry registry:2
sleep 2
curl -s http://localhost:5050/v2/coffee-api/tags/list
```

```out auto
```

Тег `1.0.0` на месте — registry хранит данные в томе `registry-data`.

**Почему `localhost` — особый случай.** Docker считает адрес `localhost:…` безопасным и ходит на него по обычному HTTP. Для любого **другого** адреса он требует **HTTPS** (TLS-сертификат) и откажется работать с простым HTTP. Воспроизведём: обратимся к registry **по его IP-адресу** внутри Docker-сети:

```bash run
RIP=$(docker inspect --format '{{.NetworkSettings.Networks.bridge.IPAddress}}' registry)
docker pull "$RIP:5000/coffee-api:1.0.0"
```

```out auto
```

`http: server gave HTTP response to HTTPS client` — Docker постучался по HTTPS, а наш registry отвечает по HTTP. Есть два правильных пути: **1)** настроить на registry **настоящий TLS** (сертификат: Let's Encrypt, свой центр сертификации) — путь для боевого реестра; **2)** для тестов явно разрешить небезопасный адрес в настройках демона: Docker Desktop → *Settings → Docker Engine* — добавить в JSON ключ `"insecure-registries": ["адрес:порт"]`, перезапустить. Второй способ — только для внутренних тестов: любой, кто сидит «посередине», увидит и подменит содержимое.

### why
Свой registry нужен там, где нельзя или не хочется использовать публичные: закрытая сеть, образы с кодом компании, скорость внутри датацентра. Знание, что «без HTTPS — только `localhost` или явное исключение», экономит час поисков, когда на сервере `pull` внезапно требует TLS.

### deep Команда по частям
`RIP=$(docker inspect --format '{{.NetworkSettings.Networks.bridge.IPAddress}}' registry)`: достаём IP-адрес контейнера в сети `bridge` и кладём в переменную `RIP`. `docker pull "$RIP:5000/…"` — обращаемся к registry по IP и **внутреннему** порту 5000 (так видит его демон внутри хоста).

### deep Как ещё можно
- **Защитить registry паролем:** обёрткой `htpasswd`-аутентификации — это ровно шаг 10.7.
- **Включить TLS:** `-e REGISTRY_HTTP_TLS_CERTIFICATE=… -e REGISTRY_HTTP_TLS_KEY=…` и монтирование сертификата; либо поставить перед registry reverse proxy (Caddy, Traefik) с автоматическим сертификатом.
- **Очистка:** удалённые образы не освобождают место сразу; нужна сборка мусора `registry garbage-collect`.

### deep Если не получилось
- **`http: server gave HTTP response to HTTPS client`** — адрес не `localhost`, а TLS не настроен (см. выше).
- **`dial tcp: connect: connection refused`** — registry не запущен или порт указан не тот (внутри Docker-сети — 5000, снаружи — 5050).
- **`manifest unknown`** — такого тега в этом registry нет: `curl …/tags/list`.

### quiz
- Что значит «стянуть образ с чистой машины» и как мы это проверили?
- Почему Docker разрешает HTTP только для `localhost`?
- Какие два способа заставить Docker работать с registry на другом адресе и какой из них для продакшна?

### links
- https://docs.docker.com/engine/daemon/#configure-the-docker-daemon | настройка демона (insecure-registries) | Configure the daemon
- https://distribution.github.io/distribution/about/deploying/ | развёртывание registry | Deploy a registry

## 10.3 GHCR: токен, login, push, видимость | short: GitHub Container Registry | est: ~45 мин
### intro
**Слова шага:** *GHCR*, *`ghcr.io`*, *Personal Access Token*, *`docker login`*, *`--password-stdin`*, *видимость пакета*.

:::tip Если совсем просто
GHCR — это **склад коробок от GitHub**, привязанный к твоему аккаунту. Чтобы положить туда коробку, нужен **пропуск** (токен). Пропуск — как пароль: его **никому не показывают и не пишут в файлы**. Положила — и можно открыть или закрыть склад для других.
:::

:::trap Этот шаг выполняется самостоятельно
Для него нужны **твой** аккаунт GitHub и **твой** токен, а токены мы не пишем в файлы и не отправляем в чат. Поэтому ниже — подробный порядок действий; в тестовой среде он **не запускался** (проверена только логика работы registry — шаги 10.1, 10.2, 10.7). Все команды ты выполнишь у себя, ориентируясь на ожидаемые результаты.
:::

**GitHub Container Registry (GHCR)** живёт по адресу `ghcr.io`. Образ называется `ghcr.io/<логин в нижнем регистре>/<имя>:<тег>`. Плюсы: бесплатно для публичных образов, интегрирован с GitHub Actions (шаг 10.6), права привязаны к репозиториям.

**Шаг 1. Создай токен.** GitHub → фото профиля → *Settings* → *Developer settings* → *Personal access tokens* → **Tokens (classic)** → *Generate new token (classic)*. Название — например, `ghcr-push`; срок — короткий (30–90 дней); галочки: **`write:packages`** (запись образов) и **`read:packages`** (чтение). *Generate token* — токен показывают **один раз**; не закрывай страницу, пока не вставишь его в терминал на следующем шаге.

**Шаг 2. Положи токен в переменную окружения, не в файл.** Команда `read -s` спрашивает значение **без вывода на экран** (в zsh на Mac):

```bash
read -s "GHCR_TOKEN?Вставь токен и нажми Enter: "
```

Вставь токен (символы не отображаются) и нажми Enter. Токен теперь только в памяти этого окна терминала. Закроешь окно — исчезнет.

**Шаг 3. Войди.** `--password-stdin` читает пароль со стандартного ввода (а не из аргумента — иначе он остался бы в истории команд). Вместо `<логин>` — твой логин GitHub:

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u <логин> --password-stdin
```

Ожидаемый результат: `Login Succeeded`. Docker сохранит учётные данные в хранилище ключей macOS (не в открытом файле).

**Шаг 4. Назови и отправь образ.** Используем образы нашего проекта. Имя в нижнем регистре; `v1.0.0` — версия:

```bash
docker tag coffee-api:slim ghcr.io/<логин>/coffeeshop-api:1.0.0
docker push ghcr.io/<логин>/coffeeshop-api:1.0.0
```

Ожидаемый результат: строки `Pushed` по каждому слою и итог `1.0.0: digest: sha256:… size: …`. Образ появится на GitHub: профиль → вкладка *Packages*.

**Шаг 5. Видимость.** Новый пакет по умолчанию **приватный** (виден только тебе). Чтобы скачивать без входа: страница пакета → *Package settings* → *Danger Zone* → *Change visibility* → **Public**. Публичный образ не должен содержать секретов — вспомни шаг 4.2: всё, что попало в слои, видно любому.

**Шаг 6. Проверь «с чистой машины».** Выйди и убедись, что публичный образ скачивается без аккаунта:

```bash
docker logout ghcr.io
docker rmi ghcr.io/<логин>/coffeeshop-api:1.0.0
docker pull ghcr.io/<логин>/coffeeshop-api:1.0.0
```

Ожидаемый результат: полная загрузка слоёв (`Pull complete`) и `Status: Downloaded newer image…`. Для **приватного** образа последняя команда ответила бы `unauthorized` — этот случай мы воспроизведём на своём registry в шаге 10.7.

### why
GHCR — стандартное место, где живут образы проектов на GitHub. Именно из него потом сервер скачивает образ (или Kubernetes, или Ansible). Привычка «токен — в переменную, не в файл, не в историю» — одна из самых важных привычек безопасности.

### deep Как ещё можно
- **В GitHub Actions токен не нужен вручную:** workflow получает встроенный `GITHUB_TOKEN` (шаг 10.6).
- **Связать пакет с репозиторием:** метка `org.opencontainers.image.source=https://github.com/<логин>/<репо>` в Dockerfile (`LABEL`) — GHCR сам привяжет пакет к репозиторию.
- **Docker Hub:** `docker login` без адреса логинит в Docker Hub; образ называется `<логин>/<имя>:<тег>`.
- **Удалить токен:** *Settings → Developer settings → Tokens* → Delete — сразу же, когда токен больше не нужен.

### deep Если не получилось
- **`denied: permission_denied: The token provided does not match expected scopes`** — у токена нет `write:packages`.
- **`unauthorized: authentication required`** — не выполнен `docker login ghcr.io` или токен просрочен.
- **`invalid reference format: repository name must be lowercase`** — в имени заглавные буквы (логин `MeeyMirita` → `meeymirita`).
- **Пакет приватный, а нужен публичный** — шаг 5 (смена видимости на странице пакета; прочитай предупреждения GitHub перед сменой — после публикации образ может быть уже скачан другими).

### quiz
- Как должен выглядеть полный адрес образа в GHCR и почему имя в нижнем регистре?
- Почему токен вводят через `read -s` и `--password-stdin`, а не пишут в команду?
- Чем приватный пакет отличается от публичного при `docker pull`?

### links
- https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry | работа с GHCR | Working with the Container registry
- https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens | токены GitHub | Managing personal access tokens

## 10.4 Теги: версии, latest как ловушка, digest | short: Теги и версии | est: ~35 мин
### intro
**Слова шага:** *семантическая версия*, *`latest`*, *неизменяемый тег*, *digest*, *несколько тегов на образ*.

:::tip Если совсем просто
Этикетка `latest` на банке — «здесь самое свежее». Но сегодня в банке одно варенье, завтра — другое, а **этикетка осталась**. Если ты вчера купила «latest», а сегодня сервер взял «latest», вы едите разное. Поэтому для серьёзных дел пишут на этикетке **номер партии** (`1.2.3`), а ещё лучше — используют **серийный номер банки** (digest).
:::

Принятый формат версий — **семантическая версия** `MAJOR.MINOR.PATCH` (`1.4.2`): `PATCH` — исправление ошибок, `MINOR` — новые возможности без поломок, `MAJOR` — несовместимые изменения. Один и тот же образ обычно получает **несколько тегов сразу**: точный `1.4.2`, «плавающие» `1.4` и `1`, и (осторожно) `latest`. Плавающие теги двигаются при каждом новом патче: кто подписан на `1.4`, автоматически получает `1.4.3`.

Покажем «ловушку `latest`»: в один и тот же тег мы по очереди загрузим **два разных образа** (`api` и `web`). Тот, кто скачал `latest` до второй загрузки, получил не то, что получит после:

```bash run
docker tag coffee-api:slim localhost:5050/demo/app:latest
docker push localhost:5050/demo/app:latest 2>&1 | tail -1
docker tag coffee-web:2 localhost:5050/demo/app:latest
docker push localhost:5050/demo/app:latest 2>&1 | tail -1
```

### result
```out auto
```

У двух `push` **разные digest**: тег `latest` в registry теперь указывает на другой образ — на первый, `api`, он уже не ссылается. Любой, кто сегодня сделает `docker pull …:latest`, получит `web`, а вчерашний пользователь получил `api`. Теперь **привязка по digest**: ссылка вида `имя@sha256:…` указывает на конкретное содержимое и не меняется никогда. Запомним digest первого образа и скачаем по нему:

```bash run
docker rmi localhost:5050/demo/app:latest > /dev/null
ACC='application/vnd.oci.image.index.v1+json, application/vnd.oci.image.manifest.v1+json'
echo "latest сейчас = $(curl -s -D - -o /dev/null -H "Accept: $ACC" http://localhost:5050/v2/demo/app/manifests/latest | grep -i docker-content-digest | tr -d '\r' | cut -d' ' -f2 | cut -c1-19)…"
echo "api-образ    = $(docker image inspect --format '{{.Id}}' coffee-api:slim | cut -c1-19)…"
```

```out auto
```

Вывод показывает: `latest` сейчас не совпадает с digest образа `api` — тег «уехал». Для воспроизводимости в Compose и CI образы закрепляют **точным тегом** (`1.4.2`) или **digest**, а `latest` оставляют для экспериментов.

Правильная схема релиза — каждая версия получает несколько тегов, и **точный тег никогда не переставляют**:

```bash run
for t in 1.0.0 1.0 1; do docker tag coffee-api:slim localhost:5050/coffeeshop/api:$t; docker push localhost:5050/coffeeshop/api:$t > /dev/null 2>&1; done
curl -s http://localhost:5050/v2/coffeeshop/api/tags/list
```

```out auto
```

Три тега ведут на **один и тот же** образ: `1.0.0` — точная версия (её не трогаем), `1.0` и `1` — плавающие (при выходе `1.0.1` их перенаправят на новый образ, а `1.0.0` останется навсегда на старом).

### why
Теги — договорённость между людьми, digest — гарантия для машин. Откат («верни прошлую версию») возможен только если прежние точные теги не перезаписаны. `latest` же в продакшне — источник непонятных поломок: «ничего не менял, а работает по-другому».

### deep Команда по частям
`for t in 1.0.0 1.0 1; do … done` — цикл оболочки: для каждого значения `t` выполнить тело (поставить тег и отправить). `curl -s -D - -o /dev/null …` — запросить только **заголовки** ответа (`-D -` печатает их, `-o /dev/null` отбрасывает тело); в заголовке `Docker-Content-Digest` лежит digest манифеста.

### deep Как ещё можно
- **Автоматические теги в CI:** `docker/metadata-action` сам создаёт `1.4.2`, `1.4`, `1` и метку из git-тега (шаг 10.6).
- **Привязка в Compose:** `image: ghcr.io/<логин>/coffeeshop-api:1.0.0@sha256:…` — тег для людей, digest для надёжности.
- **Тег по коммиту:** `:sha-3f2a9c1` — удобен для отладки, но не годится как «версия».
- **Иммутабельные теги:** многие registry (ECR, Harbor) умеют запрещать перезапись тега.

### deep Если не получилось
- **`manifest unknown`** — такого тега или digest нет в registry.
- **`curl` не вернул digest** — в `Accept` указаны не те типы манифестов (образ в формате Docker, а не OCI): добавь `application/vnd.docker.distribution.manifest.v2+json`.
- **`push` написал `Layer already exists` для всех слоёв** — нормально: слои те же, загрузился только манифест (тег).

### quiz
- Чем плох тег `latest` в продакшне?
- Что означает формат `1.4.2` и какие плавающие теги к нему добавляют?
- Чем digest надёжнее тега и когда его указывают?

### links
- https://semver.org/lang/ru/ | семантическое версионирование | SemVer
- https://docs.docker.com/build/building/best-practices/#pin-base-image-versions | фиксация версий образов | Pin base image versions

## 10.5 Git и GitFlow в минимуме | short: Git и релизы | est: ~40 мин
### intro
**Слова шага:** *репозиторий*, *коммит*, *ветка*, *слияние (merge)*, *тег*, *GitFlow*, *релиз*.

:::tip Если совсем просто
Git — **история всех изменений проекта**: можно вернуться к любому моменту. **Ветка** — отдельная «параллельная реальность», где пробуешь новое, не ломая основное. Когда довольна — **сливаешь** ветку обратно. **Тег** — закладка «вот здесь версия 1.0.0»: от неё и поедет релиз.
:::

Образы мы будем собирать и публиковать **автоматически**, когда на GitHub появляется тег с версией (шаг 10.6). Для этого нужен минимум git: репозиторий, коммиты, ветки, теги. Воспроизведём весь цикл в маленьком учебном репозитории (команды те же, что на твоём Mac; на Mac `git` уже есть):

```bash run
mkdir -p ~/docker-lab/s10/repo && cd ~/docker-lab/s10/repo
git init -q -b main
git config user.name "Мира"
git config user.email "mira@example.com"
echo "# CoffeeShop" > README.md
git add README.md
git commit -q -m "Первый коммит: README"
git log --oneline
```

### result
```out auto
```

`git init` создал репозиторий (ветка `main`), `git add` подготовил файл к записи, `git commit` записал его в историю с сообщением. Правило работы: **основная ветка (`main`) всегда рабочая**, а новое делают в отдельных ветках. Создадим ветку для новой возможности, сделаем в ней коммит и сольём обратно в `main`:

```bash run
cd ~/docker-lab/s10/repo
git switch -q -c feature/menu-page
echo "Меню: эспрессо, капучино, латте" >> README.md
git commit -q -am "Добавить описание меню"
git switch -q main
git merge -q --no-ff feature/menu-page -m "Слить feature/menu-page в main"
git log --oneline --graph --decorate
```

```out auto
```

`--graph` рисует ветки: коммит в ветке `feature/menu-page`, потом коммит слияния в `main`. Теперь **релиз** — ставим на текущий коммит **тег** с версией и смотрим теги:

```bash run
cd ~/docker-lab/s10/repo
git tag -a v1.0.0 -m "Релиз 1.0.0"
git tag
git log --oneline --decorate -3
```

```out auto
```

Тег `v1.0.0` — неподвижная закладка. На GitHub команда `git push --tags` (или `git push origin v1.0.0`) отправит тег, и по нему запустится конвейер публикации образа.

**GitFlow** — одна из договорённостей о том, как называть и использовать ветки: `main` — всегда рабочая версия; `develop` — накопление новых возможностей; `feature/*` — отдельные задачи; `release/*` — подготовка версии; `hotfix/*` — срочные исправления продакшна. Для небольших проектов чаще выбирают **упрощённую схему (trunk-based)**: одна основная ветка `main`, короткоживущие ветки `feature/*` и теги для релизов — ровно то, что мы сделали. Выбирай по размеру команды: чем меньше людей, тем проще схема.

### why
Связка «git-тег → автоматический образ» превращает релиз из ритуала в одну команду: поставила тег — и конвейер сам собрал и опубликовал образ с правильной версией. Это основа CI/CD, поэтому минимум git нужен до GitHub Actions.

### deep Команда по частям
`git init -q -b main` — создать репозиторий с веткой `main` (`-q` — тихо). `git commit -q -am "…"` — записать в историю все изменения отслеживаемых файлов (`-a`) с сообщением (`-m`). `git switch -c имя` — создать ветку и перейти на неё; `git switch main` — вернуться. `git merge --no-ff` — слить с обязательным коммитом слияния (видно в графе). `git tag -a v1.0.0 -m "…"` — аннотированный тег.

### deep Как ещё можно
- **Отправка на GitHub:** `git remote add origin git@github.com:<логин>/<репо>.git` → `git push -u origin main` → `git push origin v1.0.0`.
- **Графический клиент:** GitHub Desktop, VS Code («Source Control») показывают то же самое.
- **Pull Request:** вместо локального merge в командной работе ветку отправляют на GitHub, и слияние делают через PR (с проверками CI).
- **Как не потерять `.env`:** файл в `.gitignore` (шаг 8.4), в репозитории — `.env.example`.

### deep Если не получилось
- **`Please tell me who you are`** — не заданы `user.name` и `user.email` (команды `git config`).
- **`fatal: not a git repository`** — запускаешь не из папки репозитория.
- **Конфликт слияния (`CONFLICT`)** — один и тот же кусок файла изменён в двух ветках: открой файл, выбери нужное, убери маркеры `<<<<<<<`, `git add`, `git commit`.

### quiz
- Чем ветка отличается от тега?
- Зачем нужен `main` «всегда рабочим» и откуда берётся релиз?
- Как тег версии связан с публикацией образа?

### links
- https://git-scm.com/book/ru/v2 | книга Pro Git на русском | Pro Git
- https://docs.github.com/en/get-started/using-git/about-git | о Git | About Git

## 10.6 GitHub Actions: сборка и публикация образа по тегу | short: GitHub Actions | est: ~55 мин
### intro
**Слова шага:** *CI/CD*, *workflow*, *job*, *step*, *`on: push: tags`*, *`GITHUB_TOKEN`*, *`docker/build-push-action`*, *кэш сборки*.

:::tip Если совсем просто
GitHub Actions — **робот-сборщик на конвейере**. Ты сообщаешь роботу: «когда появится новый тег версии — собери образы, подпиши номером и отнеси на склад (GHCR)». Робот делает это сам, на чужом компьютере, одинаково каждый раз.
:::

```svg
<svg viewBox="0 0 640 170" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Релиз: git tag → GitHub Actions → GHCR → сервер" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m2-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m2-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><rect x="8" y="40" width="140" height="56" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="78.0" y="64.0" text-anchor="middle" font-size="12" fill="currentColor">git tag v1.0.0</text><text x="78.0" y="82.0" text-anchor="middle" font-size="12" fill="currentColor">git push --tags</text><line x1="148" y1="68" x2="168" y2="68" stroke="currentColor" stroke-width="1.8" marker-end="url(#m2-e)"/><rect x="168" y="40" width="140" height="56" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="238.0" y="64.0" text-anchor="middle" font-size="12" fill="currentColor">GitHub Actions</text><text x="238.0" y="82.0" text-anchor="middle" font-size="12" fill="currentColor">build + push</text><line x1="308" y1="68" x2="328" y2="68" stroke="currentColor" stroke-width="1.8" marker-end="url(#m2-e)"/><rect x="328" y="40" width="140" height="56" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="398.0" y="64.0" text-anchor="middle" font-size="12" fill="currentColor">GHCR</text><text x="398.0" y="82.0" text-anchor="middle" font-size="12" fill="currentColor">ghcr.io/…:1.0.0</text><line x1="468" y1="68" x2="488" y2="68" stroke="currentColor" stroke-width="1.8" marker-end="url(#m2-e)"/><rect x="488" y="40" width="140" height="56" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="558.0" y="64.0" text-anchor="middle" font-size="12" fill="currentColor">Сервер</text><text x="558.0" y="82.0" text-anchor="middle" font-size="12" fill="currentColor">docker pull</text><text x="320" y="135" text-anchor="middle" font-size="13" fill="currentColor" fill-opacity="0.9">каждый тег — один неизменяемый образ с понятной версией</text></svg>
```

**CI/CD** — автоматическая проверка и выкладка при каждом изменении. В GitHub это **workflow** — файл `.github/workflows/<имя>.yml` в репозитории. Его части: **`on`** — когда запускать; **`jobs`** — задания (`job`), каждое выполняется на отдельной виртуальной машине (`runs-on: ubuntu-latest`); **`steps`** — шаги внутри задания; **`uses`** — готовое действие из каталога (`actions/checkout` — скачать код репозитория). Секреты хранятся в настройках репозитория и доступны как `${{ secrets.ИМЯ }}`; для GHCR хватает встроенного **`GITHUB_TOKEN`**.

:::trap Запуск на GitHub — самостоятельно
Выполнить workflow можно только на самом GitHub, в твоём репозитории. Мы **написали файл и проверили его синтаксис линтером** `actionlint`, но реальный прогон на GitHub — твоя часть. Версии действий (`@v4`, `@v6`) могли обновиться: перед использованием загляни на страницы действий на GitHub Marketplace и возьми актуальные.
:::

Напишем workflow для CoffeeShop: по тегу `v*` собирать образы `api` и `web` и публиковать их в GHCR с тегами `1.0.0`, `1.0`, `1`:

```bash run
mkdir -p ~/docker-lab/coffeeshop/.github/workflows && cd ~/docker-lab/coffeeshop
cat > .github/workflows/publish.yml <<'EOF'
name: Publish images

on:
  push:
    tags: ["v*"]

permissions:
  contents: read
  packages: write

jobs:
  publish:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [api, web]
    steps:
      - name: Забрать код
        uses: actions/checkout@v4

      - name: Включить buildx
        uses: docker/setup-buildx-action@v3

      - name: Войти в GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Посчитать теги и метки
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository_owner }}/coffeeshop-${{ matrix.service }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}

      - name: Собрать и отправить образ
        uses: docker/build-push-action@v6
        with:
          context: ./${{ matrix.service }}
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha,scope=${{ matrix.service }}
          cache-to: type=gha,mode=max,scope=${{ matrix.service }}
EOF
docker run --rm -v "$PWD":/repo -w /repo rhysd/actionlint:latest -color=false .github/workflows/publish.yml && echo "actionlint: замечаний нет"
```

### result
```out auto
```

`actionlint` — линтер для workflow-файлов: он проверил синтаксис YAML, имена ключей и выражения `${{ … }}`, замечаний нет. Разберём файл по порядку.

- **`on.push.tags: ["v*"]`** — запускаться только при отправке тега, начинающегося на `v` (`v1.0.0`).
- **`permissions`** — минимальные права для встроенного токена: читать код и писать пакеты (принцип наименьших привилегий, шаг 5.4).
- **`strategy.matrix.service: [api, web]`** — одно задание запустится **дважды**, для `api` и для `web` (параллельно): так мы собираем два образа одним описанием.
- **`docker/login-action`** — вход в GHCR с `GITHUB_TOKEN` (никаких паролей в файле).
- **`docker/metadata-action`** — вычисляет теги по git-тегу: из `v1.4.2` получатся `1.4.2`, `1.4` и `1` (шаг 10.4) и метки образа.
- **`docker/build-push-action`** — сборка из `./api` или `./web` и публикация; **кэш в GitHub Actions** (`type=gha`) ускоряет следующие сборки (шаг 4.4).

Как запустить: положи проект в репозиторий на GitHub (папка `coffeeshop` целиком, **без `.env`** — он в `.gitignore`), отправь `main`, затем:

```bash
git tag v1.0.0
git push origin v1.0.0
```

В репозитории вкладка **Actions** покажет запуск; через пару минут во вкладке **Packages** профиля появятся образы `coffeeshop-api` и `coffeeshop-web` с тегами `1.0.0`, `1.0`, `1`. Если пакеты приватные, сделай их публичными (шаг 10.3, пункт 5).

### why
Это замыкает цепочку: **код → тег → образ в registry**. Человек не собирает образы руками и не носит их на склад; сборка воспроизводима (одно и то же окружение), а версия в имени образа всегда совпадает с версией в git. Дальше сервер, Kubernetes или Ansible просто берут образ из registry.

### deep Команда по частям
`docker run --rm -v "$PWD":/repo -w /repo rhysd/actionlint:latest -color=false`: запускаем образ линтера, подключаем текущую папку как `/repo` и делаем её рабочей (`-w /repo`); в конце — путь к проверяемому файлу (без пути `actionlint` ищет `.github/workflows` в корне git-репозитория). В `${{ matrix.service }}` и `${{ steps.meta.outputs.tags }}` двойные фигурные скобки — выражения GitHub Actions, значения подставляются при запуске.

### deep Как ещё можно
- **Добавить проверки до публикации:** отдельный job `test` с `needs:` и сканированием образа Trivy (шаг 5.5).
- **Ручной запуск:** добавить `workflow_dispatch:` в `on:` — кнопка «Run workflow».
- **Запуск при каждом push в `main`:** `on: push: branches: [main]` и тег `main`/`sha-…` вместо семвера.
- **Мультиплатформенные образы:** добавить `docker/setup-qemu-action` и `platforms: linux/amd64,linux/arm64` в `build-push-action` (шаг 5.3).
- **Локальная проверка:** утилита `act` запускает workflow в Docker на твоём компьютере (не весь функционал Actions).

### deep Если не получилось
- **Workflow не запускается** — тег отправлен не в тот репозиторий, имя тега не начинается с `v`, или файл лежит не в `.github/workflows/`.
- **`denied: installation not allowed to Create organization package`** / `permission denied` при push — в настройках репозитория *Settings → Actions → General → Workflow permissions* включи «Read and write permissions», и проверь блок `permissions` в файле.
- **`repository name must be lowercase`** — логин с заглавными: `metadata-action` приводит имя к нижнему регистру сам; если пишешь вручную, используй нижний.
- **`context path ... does not exist`** — путь `context` неверный: в репозитории должны быть папки `api` и `web` в корне.

### quiz
- Какие три части workflow ты назовёшь (`on`, `jobs`, `steps`) и что делает каждая?
- Зачем `strategy.matrix` и что получится при `service: [api, web]`?
- Откуда берутся теги `1.4.2`, `1.4`, `1` и почему токен для GHCR не хранят в файле?

### links
- https://docs.github.com/en/actions/use-cases-and-examples/publishing-packages/publishing-docker-images | публикация Docker-образов | Publishing Docker images
- https://github.com/docker/build-push-action | build-push-action | build-push-action
- https://github.com/rhysd/actionlint | actionlint | actionlint

## 10.7 🔨 Сломать → починить: unauthorized при pull приватного образа | short: unauthorized | est: ~45 мин
### intro
**Слова шага:** *аутентификация*, *basic auth*, *`htpasswd`*, *`docker login` / `logout`*, *`unauthorized`*, *`no basic auth credentials`*.

:::tip Если совсем просто
Приватный склад пускает только по пропуску. Забыла пропуск — тебя не пустят, и охранник скажет **ровно, чего не хватает**. Научимся читать его слова: «пропуска нет» — это одно, «пропуск не тот» — другое.
:::

Самая частая беда с приватными образами: `pull` отвечает `unauthorized`. Воспроизведём честно на **своём приватном registry** с паролем (так же устроены GHCR и закрытые реестры компаний). Создадим файл с логином и паролем (`htpasswd`, хэш bcrypt) и запустим registry с включённой проверкой. Учётные данные — учебные, и в тестовой среде:

```bash run
mkdir -p ~/docker-lab/s10/auth && cd ~/docker-lab/s10/auth
docker run --rm --entrypoint htpasswd httpd:2 -Bbn mira lab-password > htpasswd
docker run -d --name private-registry -p 5051:5000 \
  -v "$PWD":/auth \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM="Private" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  registry:2 > /dev/null
sleep 2
docker tag coffee-api:slim localhost:5051/private/api:1.0.0
echo "--- 1. push без входа:"
docker push localhost:5051/private/api:1.0.0 2>&1 | tail -2
```

### result
```out auto
```

Сообщение заканчивается словами **`no basic auth credentials`** — «нет учётных данных»: Docker не передал серверу логин и пароль, потому что мы не входили. В начале — `push access denied, repository does not exist or may require authorization`: так Docker подсказывает, что в таких случаях registry не говорит, существует ли репозиторий (чтобы не выдавать лишнего чужим). Теперь попробуем войти **с неверным паролем**, затем с верным, и отправим образ:

```bash run
cd ~/docker-lab/s10/auth
echo "--- 2. вход с неверным паролем:"
echo "wrong-password" | docker login localhost:5051 -u mira --password-stdin 2>&1 | grep -iE 'unauthorized|incorrect|denied|Succeeded'
echo "--- 3. вход с верным паролем и push:"
echo "lab-password" | docker login localhost:5051 -u mira --password-stdin 2>&1 | grep -iE 'unauthorized|incorrect|denied|Succeeded'
docker push localhost:5051/private/api:1.0.0 2>&1 | tail -1
echo "--- 4. выход и pull:"
docker logout localhost:5051
docker rmi localhost:5051/private/api:1.0.0 > /dev/null
docker pull localhost:5051/private/api:1.0.0 2>&1 | tail -2
```

```out auto
```

Разберём по пунктам. **2.** Неверный пароль: сервер отвечает кодом **`401 Unauthorized`**, и `docker login` пишет `login attempt … failed with status: 401 Unauthorized` — сервер получил логин и пароль, но они не подошли (в других реестрах и при `push`/`pull` с неверным токеном текст бывает `unauthorized: incorrect username or password`). **3.** С верным паролем `Login Succeeded`, и `push` прошёл. **4.** После `docker logout` данные снова не отправляются, и `pull` отвечает так же, как в первом случае: **`pull access denied … no basic auth credentials`**. Таких сообщений несколько, и различать их полезно:

| Сообщение | Что значит | Что делать |
|---|---|---|
| `… authorization failed: no basic auth credentials` | клиент не прислал логин и пароль (не входил или вышел) | `docker login <registry>` |
| `… failed with status: 401 Unauthorized` / `unauthorized: incorrect username or password` | пропуск неверный | проверь логин и пароль/токен, не истёк ли токен |
| `unauthorized: authentication required` | нужен вход (или вход выполнен на другой адрес) | `docker login` на **тот же адрес**, что в имени образа |
| `denied: requested access to the resource is denied` | вход есть, но у тебя **нет прав** на этот репозиторий | попроси доступ; проверь имя репозитория и права токена |
| `denied: permission_denied: … scopes` (GHCR) | у токена не хватает прав (`read:packages` / `write:packages`) | выпусти токен с нужными правами |

Починка: войти и повторить:

```bash run
cd ~/docker-lab/s10/auth
echo "lab-password" | docker login localhost:5051 -u mira --password-stdin 2>&1 | grep -iE 'Succeeded'
docker pull localhost:5051/private/api:1.0.0 2>&1 | tail -2
docker logout localhost:5051
```

```out auto
```

Вход вернул доступ, образ скачался. Убираем за собой учебные registry и том (по именам, не `prune`):

```bash run
docker rm -f private-registry registry > /dev/null
docker volume rm registry-data
docker images --format '{{.Repository}}' | grep -E '^localhost' | sort -u | xargs -r docker rmi > /dev/null 2>&1
docker ps -a --format '{{.Names}}' | grep -E 'registry' || echo "registry-контейнеров не осталось"
```

```out auto
```

### why
`unauthorized` и `access denied` вызывают панику, а на самом деле сообщение всегда точное: либо не вошла, либо вошла не туда, либо неверный пароль, либо нет прав. Читай слова в конце сообщения — и по таблице выше найдёшь причину за минуту. Тот же алгоритм работает и в GHCR, и в Docker Hub, и в закрытом реестре компании.

### deep Если не получилось
- **`htpasswd: command not found` в контейнере `httpd`** — образ `httpd:2` содержит утилиту; запуск должен идти с `--entrypoint htpasswd`.
- **Registry отвечает `401` даже после входа** — `docker login` выполнен на другой адрес (`127.0.0.1` вместо `localhost`): Docker запоминает пароль для **точного** адреса.
- **`WARNING! Your credentials are stored unencrypted`** — в тестовой среде нет хранилища ключей (мы отфильтровали это предупреждение); на Mac пароль уходит в Keychain.

### quiz
- Чем `no basic auth credentials` отличается от `incorrect username or password` и от `denied`?
- Почему важно входить на **тот же адрес**, что в имени образа?
- Какие три проверки ты сделаешь, если `pull` приватного образа из GHCR ответил `unauthorized`?

### outro
:::tip Приёмка сессии 10
- Ты объясняешь, из чего состоит образ в registry (тег → манифест → слои), и показываешь это HTTP-запросами к своему registry.
- Ты поднимаешь свой registry, делаешь `push`, удаляешь образ локально и скачиваешь его заново, и знаешь, почему «не localhost» требует HTTPS.
- **Выполняется самостоятельно (твой аккаунт и токен):** создаёшь токен, входишь в GHCR через `read -s` и `--password-stdin`, отправляешь образ, меняешь видимость пакета и проверяешь `pull` без входа.
- Ты называешь образы семантическими версиями (`1.0.0`, `1.0`, `1`), не используешь `latest` в продакшне и закрепляешь образ по digest, когда нужна гарантия.
- Ты проходишь цикл git: коммит, ветка, слияние, тег `v1.0.0`.
- Workflow `.github/workflows/publish.yml` написан и проверен `actionlint`; **запуск на GitHub выполняется самостоятельно:** тег `v1.0.0` → образы в GHCR.
- Ты читаешь сообщения `unauthorized` / `denied` и по таблице находишь причину.
:::
