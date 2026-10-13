# 2 · Справочник ошибок: симптом → причина → что делать | short: Справочник ошибок | kind: ref
Ошибки Docker всегда читай **справа налево**: последняя фраза обычно и есть причина. Диагностика — сверху вниз: клиент → демон → образ → контейнер → сеть → том. Для контейнера: **`docker ps -a` → `docker logs` → `docker inspect`**.

**Демон и установка**

| Симптом | Причина | Что делать |
|---|---|---|
| `failed to connect to the docker API at …` (старое: `Cannot connect to the Docker daemon … Is the docker daemon running?`) | демон не запущен или клиент смотрит не туда | запусти Docker Desktop; `docker context ls`; `unset DOCKER_HOST` (1.7) |
| `permission denied while trying to connect to the Docker daemon socket` | (Linux) пользователь не в группе `docker` | `sudo usermod -aG docker $USER`, перелогинься |
| `docker: command not found` | Docker не установлен или не в `PATH` | установи Docker Desktop, запусти один раз, перезапусти терминал |
| `no space left on device` | диск VM заполнен образами, томами, кэшем | `docker system df`; удали **свои** ненужные образы и тома по имени; увеличь диск в Settings → Resources |
| `exec format error` | образ для другой архитектуры (amd64 на ARM) | `--platform linux/amd64` или образ под свою архитектуру (3.4) |

**Образы и registry**

| Симптом | Причина | Что делать |
|---|---|---|
| `toomanyrequests` | лимит загрузок Docker Hub | подожди или `docker login` (1.4) |
| `manifest unknown` / `not found` при pull | нет такого тега | проверь опечатку и список тегов (3.2, 10.2) |
| `pull access denied … may require authorization` | приватный образ или не выполнен вход | `docker login`; проверь имя и права (10.7) |
| `no basic auth credentials` | клиент не прислал логин и пароль | `docker login <registry>` (10.7) |
| `denied: permission_denied … scopes` (GHCR) | у токена не хватает прав | токен с `write:packages` / `read:packages` (10.3) |
| `http: server gave HTTP response to HTTPS client` | registry на не-localhost адресе без TLS | настрой TLS или `insecure-registries` (10.2) |
| `repository name must be lowercase` | заглавные буквы в имени образа | имя в нижнем регистре (10.3) |
| образ «раздулся» после удаления файла | слои неизменяемы | создавать и удалять в одной `RUN` (3.7) |

**Сборка (Dockerfile)**

| Симптом | Причина | Что делать |
|---|---|---|
| `COPY failed: file not found in build context` | файла нет в контексте | путь относительно папки сборки; проверь `.dockerignore` (4.1) |
| каждая правка кода пересобирает `npm ci` | `COPY . .` стоит раньше установки зависимостей | сначала `package*.json` и установка, потом код (4.7) |
| `npm error Cannot read "package-lock.json"` | нет lock-файла | `npm install --package-lock-only` (4.5) |
| `COPY --from=…: invalid from flag value` | имя этапа не совпадает | сверь `AS` и `--from` (5.2) |
| `unknown flag: --mount` | старый Docker без BuildKit | обнови Docker (5.3) |
| `permission denied` после `USER` | файлы созданы root, процесс — обычный пользователь | `chown` или `COPY --chown`, `USER` — после (5.7) |
| `exec: "…": executable file not found in $PATH` | в образе нет такой программы (в distroless нет `sh`) | проверь команду и образ; для отладки — `docker debug` (3.4, 5.2) |

**Запуск контейнера**

| Симптом | Причина | Что делать |
|---|---|---|
| `Conflict. The container name … is already in use` | имя занято (в том числе остановленным контейнером) | `docker rm имя` или другое имя (2.1) |
| `port is already allocated` / `Bind for 0.0.0.0:… failed` | порт хоста занят | другой порт слева в `-p`; на Mac 5000 и 7000 занимает AirPlay (2.2, 6.2) |
| контейнер сразу `Exited (0)` | главный процесс завершился | запускай долгоживущий процесс (2.7) |
| `Exited (1)` | ошибка приложения | `docker logs имя` (2.7) |
| `Exited (137)` | убит SIGKILL: тайм-аут `stop` или нехватка памяти | `OOMKilled`? `docker inspect`; `exec` в entrypoint (2.6, 4.6, 9.4) |
| `docker stop` висит 10 секунд | процесс с PID 1 не слушает SIGTERM | exec-форма `CMD`, `exec "$@"` в entrypoint (4.6) |
| `permission denied` при записи в смонтированную папку | UID процесса не совпадает с владельцем | `chown`, `--user` (7.5) |
| `Read-only file system` | включён `read_only`, а приложение пишет на диск | `tmpfs` или том для нужной папки (5.4, 11.2) |
| `unhealthy` | `healthcheck` не проходит | проверь команду вручную, `start_period`, логи (4.2, 8.5) |
| `(health: starting)` долго | проверка ещё не прошла первый интервал | подожди; проверь `interval` и `retries` |

**Сети**

| Симптом | Причина | Что делать |
|---|---|---|
| `bad address 'имя'` / имя не находится | контейнеры в разных сетях или в сети по умолчанию | своя общая сеть, `docker network inspect` (6.3, 6.7) |
| `Connection refused` | имя найдено, но порт закрыт или приложение слушает `127.0.0.1` | приложение должно слушать `0.0.0.0`; проверь порт (6.7) |
| `502 Bad Gateway` в nginx | не достучался до upstream | сети, имя сервиса, запущен ли сервис; `resolver 127.0.0.11` (6.6) |
| `host not found in upstream` при старте nginx | `proxy_pass` с именем без `resolver`/переменной | `set $upstream …; proxy_pass $upstream` + `resolver` (6.6) |
| `curl: (7) Failed to connect` | не опубликован порт или контейнер ещё стартует | `-p`, подожди секунду, `docker ps` (2.2) |

**Тома и данные**

| Симптом | Причина | Что делать |
|---|---|---|
| данные пропали после пересоздания | нет именованного тома (анонимный остался «осиротевшим») | именованный том (7.1, 7.7) |
| PostgreSQL 18: `… there appears to be PostgreSQL data in /var/lib/postgresql/data` | том смонтирован в старый путь | монтируй в `/var/lib/postgresql` (7.7) |
| `could not read from input file: Is a directory` | вместо файла смонтирована папка (`-v` создал её) | создай файл заранее, используй `--mount` (7.3, 7.7) |
| `Database is uninitialized and superuser password is not specified` | не задан `POSTGRES_PASSWORD` | переменная при запуске (2.7) |
| `init.sql` не выполнился | инициализация только при пустом томе | удали том (7.6) |
| `volume is in use` | том подключён к контейнеру | удали контейнер, потом том (7.2) |

**Compose**

| Симптом | Причина | Что делать |
|---|---|---|
| `no configuration file provided: not found` | не та папка | перейди в папку с `compose.yaml` или `-f` (8.2) |
| `go-yaml load error … mapping values are not allowed` | отступ, табуляция или двоеточие в значении без кавычек | `docker compose config`; пробелы, кавычки (8.1) |
| `required variable … is missing a value` | `${VAR:?…}` без значения | задай в `.env` (8.4) |
| `variable … is not set. Defaulting to a blank string` | `${VAR}` нигде не задана | `.env`, оболочка или значение по умолчанию (8.4) |
| `dependency failed to start: … is unhealthy` | `healthcheck` зависимости не проходит | `docker compose logs <сервис>` (8.5) |
| `dependency failed to start: … has no healthcheck configured` | `condition: service_healthy` без `healthcheck` | добавь `healthcheck` зависимости (8.5) |
| `ECONNREFUSED` у приложения при старте | гонка: база ещё не готова | `healthcheck` + `service_healthy` (8.7) |
| `port is already allocated` при `--scale` | фиксированный порт у масштабируемого сервиса | не публикуй порт, поставь балансировщик (9.5) |
| `orphan containers` | в проекте остались контейнеры удалённых из файла сервисов | `--remove-orphans` (8.3) |
| сервис в `Restarting` | процесс падает, политика `restart` поднимает снова | `logs`, чини причину (9.4) |
