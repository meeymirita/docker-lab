# Docker Lab — план большой лабы

> **Реализовано 13.10.2026.** Методичка `docker.html` переписана в большой формат (12 сессий, 77 шагов, ~44 ч), собрана из Markdown-исходников `src/*.md` генератором `tools/build-manual.py`, все выводы — настоящий прогон в изолированном Docker-в-Docker. **Отличия от плана ниже:** (1) Swarm (прежняя сессия 11) **не вошёл** — решение владельца: не нужен для Traefik, Kubernetes и Ansible; (2) сессия 11 — «Итоговый проект» (образы без root и уязвимостей, prod с `read_only`, чек-лист релиза скриптом, релиз из registry, `starter/`, Production Hell 2); (3) сессия 12 — итоговое ТЗ без ответа (сервисы `report` и `backup`), как требует стандарт лаб от 13.10; (4) Production Hell 1 — в сессии 9; (5) в каждом шаге добавлены блок «Если совсем просто» и схемы (просьба владельца); (6) профили dev/prod реализованы через `compose.override.yaml` и `compose.prod.yaml`; (7) GHCR и запуск workflow на GitHub помечены «выполняется самостоятельно» (токен и аккаунт); (8) папка `starter/` в репозиторий Docker-лабы не кладётся: ученица собирает её в шаге 11.5, а лабы-продолжения берут копию при их написании. Текст ниже — исходный план от 11.10, оставлен для истории.

> Общие правила (режимы «с нуля»/«продолжение», **стандарт подробности «каждое слово объяснено»**, размер) — в `fixes/common/_standard-lab.md` родительского репозитория `anitech-performance`. Продолжение этой лабы — Ansible: план в репозитории `ansible-lab`. Bash — отдельная лаба `bash-lab`. Исходный интернет-список (14 разделов) — в истории родителя, коммит `d6104a5`.

**Место в последовательности: №2 из 5** (после Bash); общий порядок прохождения и создания — `fixes/common/_order.md`.

## Что делаем с готовой лабой
Готовая `docker.html` (3 сессии, ~10 ч, Docker + немного Bash) **переписывается в большую** (12 сессий, ~48 ч). Проверенные примеры (Node.js + PostgreSQL, entrypoint, wait-скрипт, multi-stage, Compose) сохраняются как ядро; вокруг них — азбука, разбор каждого слова и недостающие темы. Bash уходит в отдельную лабу (в Docker остаётся ровно то, что нужно для `entrypoint.sh`).

## Паспорт и сессии

| | |
|---|---|
| Режим | **самостоятельная**; Bash желательно, но не обязателен (минимум объясняется в тексте) |
| Размер | 12 сессий × ~4 ч = **~48 ч**, ~80 шагов |
| Сквозной проект | **CoffeeShop**: Node.js API + статический frontend + PostgreSQL + Adminer (то же приложение дальше едет в Ansible, Traefik, Kubernetes) |
| Версии | Docker Engine и Compose — актуальные стабильные (сверьтесь), PostgreSQL 18, Node 24, nginx 1.30 |
| Выход | `starter/` для следующих лаб: исходники CoffeeShop + `compose.yaml` + образ, публикуемый в GHCR |
| Ограничение | Docker Desktop запускается только с согласия; после прогонов — чистить только созданное |

**Откуда темы исходного списка:** разд. 1 (введение, окружение) → сессия 1; разд. 2 (основы) → 2; разд. 3 (образы, Dockerfile) → 3–5; разд. 4 (сети) → 6; разд. 5 (хранение) → 7; разд. 6 (Compose) → 8–9; разд. 7 (Registry) → 10; разд. 11 (Swarm) → 11 (одна сессия). Git/GitFlow — в 10 (кратко, как часть CI). VirtualBox/Ubuntu/SSH-ключи — в часть II.

### Сессия 1 · Азбука контейнеров и установка (~4 ч)
**Слова:** виртуальная машина, контейнер, образ, ядро, namespace, cgroup, демон, клиент, `containerd`, `runc`, registry.
- 1.1 Проблема «у меня работает»; VM и контейнер (аналогия: квартира в доме vs отдельный дом)
- 1.2 Устройство Docker: клиент `docker` → демон `dockerd` → `containerd` → `runc`; что такое namespaces и cgroups (картинка)
- 1.3 Установка: **Docker Desktop на Mac** (что внутри — Linux-VM), **Docker Engine на Linux**, **Colima/OrbStack** как альтернативы; настройка ресурсов (память/диск)
- 1.4 `docker version`, `docker info` — каждая строка вывода; `docker run hello-world` и что при этом происходит по шагам
- 1.5 Linux-минимум для Docker: файловая система, процессы, порты, права (отсылка к Bash Lab)
- 1.6 Режимы прохождения: «с нуля» и «своя папка»; рабочая структура лабы
- 🔨 демон не запущен: `Cannot connect to the Docker daemon…` — что делать
- **Приёмка:** `hello-world` отработал, могу пересказать путь команды до `runc`

### Сессия 2 · Контейнеры и жизненный цикл (~4 ч)
**Слова:** `run`, `create`, `start`, `stop`, `kill`, `rm`, foreground/background, `-d -p -e --name --rm -it`, PID 1, exit code.
- 2.1 Состояния контейнера: created → running → paused → exited → removed (диаграмма и команды)
- 2.2 `docker run`: разбор каждого флага; `-p host:container` и откуда берётся `localhost`
- 2.3 `ps`, `ps -a`, `stop` (SIGTERM → SIGKILL), `kill`, `rm`, `restart`, `pause`
- 2.4 `logs` (`-f --since --tail`), `exec -it`, `attach` (чем отличается), `cp`
- 2.5 `inspect` с `--format`, `stats`, `top`, `events`, `diff`
- 2.6 Переменные окружения и сигналы; код возврата, `exit 137` и `exit 143`
- 🔨 контейнер стартует и сразу «Exited (0)»
- **Приёмка:** запущен `nginx`, получена страница, найден и убит «зависший» контейнер

### Сессия 3 · Образы (~4 ч)
**Слова:** образ, слой, тег, digest, `latest`, registry, Docker Hub, union filesystem, content-addressable.
- 3.1 Образ = стопка слоёв только для чтения + слой записи контейнера
- 3.2 `pull`, `images`, `rmi`, `tag`, `save/load`, `export/import`; теги и `@sha256`
- 3.3 `docker history`, `inspect`, `dive` — как увидеть слои и их размер
- 3.4 Базовые образы: `alpine` vs `slim` vs `distroless` vs `scratch` (музl vs glibc)
- 3.5 Docker Hub: поиск, официальные образы, лимиты, как читать страницу образа
- 3.6 Первый `Dockerfile` из 4 строк и `docker build`, что за контекст `.`
- 🔨 образ «пухнет»: найти слой, который его раздул
- **Приёмка:** образ из 4 строк собран, слои объяснены

### Сессия 4 · Dockerfile полностью (~4 ч)
**Слова:** инструкция, контекст сборки, кэш слоёв, `ARG` vs `ENV`, `ENTRYPOINT` vs `CMD`, exec/shell-форма, `.dockerignore`.
- 4.1 `FROM`, `WORKDIR`, `COPY` vs `ADD`, `RUN` (shell vs exec), `EXPOSE`
- 4.2 `ENV`, `ARG`, `LABEL`, `USER`, `VOLUME`, `HEALTHCHECK`, `STOPSIGNAL`, `SHELL`
- 4.3 `ENTRYPOINT` + `CMD`: четыре сочетания, форма exec и почему PID 1 важен
- 4.4 Кэш: порядок инструкций, «ломающий» кэш `COPY . .`, `.dockerignore`
- 4.5 Контейнеризация CoffeeShop API (Node 24): `package.json`, `npm ci`, запуск не от root
- 4.6 Минимальный `entrypoint.sh` и `exec "$@"` (с отсылкой к Bash Lab)
- 🔨 «правка одной строки пересобирает всё» — исправить порядок слоёв
- **Приёмка:** API собран, запущен, отвечает `/health`; пересборка после правки кода — секунды

### Сессия 5 · Оптимизация, multi-stage, безопасность образа (~4 ч)
**Слова:** multi-stage, BuildKit, `--mount=type=cache`, SBOM, CVE, `non-root`, `read-only`, capabilities.
- 5.1 Размер и скорость: «до/после» в цифрах
- 5.2 Multi-stage: сборка отдельно, запуск отдельно; `COPY --from`; `target`
- 5.3 BuildKit: кэш `--mount=type=cache`, секреты сборки `--mount=type=secret`, `buildx`, мультиархитектура (arm64/amd64)
- 5.4 Безопасность: не-root, `--read-only`, `--cap-drop ALL`, `no-new-privileges`
- 5.5 Сканирование образов (`docker scout`/`trivy`) и чтение отчёта
- 5.6 Контейнеризация frontend (nginx 1.30, статика)
- 🔨 после перехода на non-root — `permission denied`
- **Приёмка:** образ API < заданного размера, сканер без критичных находок или они объяснены

### Сессия 6 · Сети (~4 ч)
**Слова:** сетевой драйвер, bridge, NAT, порт публикации, DNS контейнеров, alias, изоляция.
- 6.1 Модель сети: у контейнера свой сетевой стек; bridge по умолчанию (`docker0`)
- 6.2 `-p` разобран: что делает Docker на хосте (NAT), `127.0.0.1:80:80`, `EXPOSE` ≠ публикация
- 6.3 Пользовательские сети и **DNS по имени** (в дефолтной bridge его нет)
- 6.4 Драйверы `host`, `none`, `overlay` (обзор), `macvlan` (обзор); ограничения на Mac (VM)
- 6.5 Подключение к нескольким сетям, `network connect/disconnect`, alias
- 6.6 Диагностика: `netshoot`, `nslookup`, `curl`, `ss`, `docker network inspect`
- 🔨 «контейнер A не видит B» (разные сети / стартует раньше)
- **Приёмка:** frontend → API → БД в одной сети, БД недоступна снаружи

### Сессия 7 · Хранение данных (~4 ч)
**Слова:** volume, bind mount, tmpfs, слой записи, драйвер тома, владелец/UID, бэкап.
- 7.1 Зачем: данные внутри контейнера умирают вместе с ним (показать)
- 7.2 Named volumes: создание, `inspect`, где лежат (в VM на Mac), `prune` осторожно
- 7.3 Bind mounts: плюсы и подводные камни (права, производительность на Mac, отсутствующий путь → каталог)
- 7.4 `tmpfs`, инструкция `VOLUME`, `--mount` vs `-v`
- 7.5 `docker cp`, права и UID/GID
- 7.6 PostgreSQL 18: том монтируется в `/var/lib/postgresql`; бэкап `pg_dump` и восстановление в новый том
- 🔨 «данные пропали после пересоздания» / «Is a directory»
- **Приёмка:** БД пережила `docker rm`, бэкап восстановлен

### Сессия 8 · Compose, часть 1 (~4 ч)
**Слова:** YAML, сервис, проект, `compose.yaml`, `depends_on`, `healthcheck`, `.env`, интерполяция.
- 8.1 YAML с нуля: отступы, списки, словари, строки, якоря
- 8.2 Структура `compose.yaml`: `services`, `networks`, `volumes`, что стало из `docker run`-команд
- 8.3 `up`, `down`, `ps`, `logs`, `exec`, `build`, `config`; `-p` и имя проекта
- 8.4 Переменные: `environment`, `env_file`, `.env`, интерполяция `${VAR:-default}`, приоритеты
- 8.5 `depends_on` + `healthcheck` + `condition`; «запущен» ≠ «готов»
- 8.6 Запуск полного CoffeeShop (API + frontend + БД + Adminer)
- 🔨 приложение стартует раньше БД
- **Приёмка:** `docker compose up` на чистой папке поднимает сайт

### Сессия 9 · Compose, часть 2 (~4 ч)
**Слова:** профиль, override, `include`, `extends`, `watch`, `restart`, лимиты, `scale`.
- 9.1 `profiles` (dev/prod/tools), несколько файлов `-f`, `compose.override.yaml`
- 9.2 Переиспользование: `include`, `extends`, якоря `&`/`*`, `x-` расширения
- 9.3 `compose watch` — разработка с автообновлением
- 9.4 `restart`-политики, лимиты `mem_limit`/`cpus`, `logging`, `stop_grace_period`
- 9.5 Масштабирование `--scale` и ограничения (порты)
- 9.6 Мини-проект: dev и prod одним репозиторием
- 🔨 **Production Hell 1:** стек из 5 сервисов с 5 поломками
- **Приёмка:** dev и prod стартуют разными командами

### Сессия 10 · Registry, GHCR, CI (~4 ч)
**Слова:** registry, репозиторий, тег, digest, токен доступа, `docker login`, workflow, GitFlow.
- 10.1 Устройство registry: манифест, слои, `pull` по шагам
- 10.2 Свой registry (`registry:2`), `push`/`pull`, `localhost:5000`, небезопасные registry
- 10.3 GHCR: создание токена (**только в переменную окружения**), `docker login ghcr.io`, push, приватность
- 10.4 Теги: семвер, `latest` как ловушка, привязка по digest
- 10.5 Git и GitFlow в минимуме (ветки, теги, релиз) — как основа для CI
- 10.6 GitHub Actions: сборка и публикация образа по тегу, кэш сборки
- 🔨 `unauthorized` при `pull` приватного образа
- **Приёмка:** тег `v1.0.0` → образ в GHCR → `pull` на «чистой» машине

### Сессия 11 · Docker Swarm (по желанию, ~4 ч)
> Одна сессия: знакомство с оркестрацией на малом масштабе. Можно пропустить без потерь для Traefik, Kubernetes и Ansible. Тяжело для ноутбука (узлы-контейнеры `docker:dind`) — предупредить заранее.

**Слова:** кластер, manager/worker, service, task, replica, overlay-сеть, routing mesh, stack, secret, Raft.
- 11.1 Зачем оркестрация; Swarm vs Kubernetes (честно: где Swarm ещё встречается)
- 11.2 `swarm init`, `node ls`; дополнительные узлы как контейнеры `docker:dind`
- 11.3 Service, Task, replicas, `service ps`, `scale`; rolling update и откат
- 11.4 Overlay-сеть, routing mesh; `docker stack deploy` из `compose.yaml`
- 11.5 Secrets (пароль БД — не в окружении); отказ узла — задачи перезапланировались
- 🔨 сервис «0/3 реплик»: найти причину
- **Приёмка:** сервис с 3 репликами переживает падение узла

### Сессия 12 · Итоговый проект Docker (~4 ч)
**Слова:** production-образ, мульти-окружение, healthcheck, откат, чек-лист релиза.
- 12.1 Сборка итогового CoffeeShop: образы API и frontend (multi-stage, non-root, сканер без критичного)
- 12.2 `compose.yaml` с профилями `dev`/`prod`, healthcheck, лимиты, логи
- 12.3 Публикация в GHCR по тегу через GitHub Actions
- 12.4 Подготовка `starter/` для Traefik, Kubernetes и Ansible (исходники, `compose.yaml`, образ)
- 12.5 (по желанию) тот же стек как `stack` в Swarm
- 🔨 **Production Hell** без подсказок: стек из 5 сервисов с 5 поломками
- **Приёмка:** `docker compose --profile prod up` на чистой машине поднимает сайт; образ из GHCR запускается

**Справка:** симптом → причина → что делать (`Cannot connect to the Docker daemon`, `port is already allocated`, `no space left on device`, `exec format error`, `OCI runtime`…), команды с разбором, порты и процессы, глоссарий, 50 вопросов для собеседования, «что дальше» (Traefik, Ansible).

## Решения владельца (11.10.2026)
1. Docker переписывается в большую (12 сессий) в том же репозитории — принято.
2. Ansible — отдельная лаба `ansible-lab` (создана 11.10.2026).
3. Swarm остаётся внутри Docker (сессия 11) — решение делегировано, принято так.
4. VM-путь (Vagrant/VirtualBox) — только как необязательный вариант в сессии 9 Ansible; основной стенд — контейнеры с `sshd`.
