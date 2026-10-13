# 1 · Шпаргалка: команды Docker и Compose | short: Шпаргалка | kind: ref
**Информация и проверка**

| Команда | Что делает |
|---|---|
| `docker version` / `docker info` | версии клиента и сервера / сведения о демоне |
| `docker context ls` | к какому демону подключён клиент |
| `docker system df` | сколько места занимают образы, контейнеры, тома, кэш |
| `docker compose version` / `docker buildx version` | версии расширений |

**Контейнеры**

| Команда | Что делает |
|---|---|
| `docker run [флаги] образ [команда]` | создать и запустить контейнер |
| `-d` · `--name` · `--rm` · `-it` | в фоне · имя · удалить после выхода · интерактивно |
| `-p хост:контейнер` · `-p 127.0.0.1:хост:контейнер` | опубликовать порт · только для localhost |
| `-e ИМЯ=значение` · `--env-file файл` | переменные окружения |
| `-v том:путь` · `-v "$PWD":путь:ro` · `--tmpfs путь` | том · bind mount (только чтение) · память |
| `--network имя` · `--network-alias имя` | сеть · псевдоним в сети |
| `-m 128m` · `--cpus 0.5` · `--pids-limit 100` | лимиты ресурсов |
| `--read-only` · `--cap-drop ALL` · `--user 1000:1000` | защита и пользователь |
| `docker ps` / `ps -a` | работающие / все контейнеры |
| `docker stop` · `kill` · `start` · `restart` · `rm` · `rm -f` | управление |
| `docker logs [-f] [--tail N] имя` | логи |
| `docker exec [-it] имя команда` | выполнить команду внутри |
| `docker cp источник цель` | копировать файлы (контейнер:путь) |
| `docker inspect --format '{{…}}' имя` | подробности по шаблону |
| `docker stats --no-stream` · `top` · `diff` · `events` | ресурсы · процессы · изменения ФС · события |

**Образы**

| Команда | Что делает |
|---|---|
| `docker images` · `docker image ls` | список образов |
| `docker pull образ[:тег]` · `docker push образ` | скачать · отправить |
| `docker tag источник цель` · `docker rmi имя` | добавить имя · удалить имя |
| `docker history образ` | слои и их размер |
| `docker image inspect образ` | метаданные образа |
| `docker save -o файл.tar образ` · `docker load -i файл.tar` | образ в файл и обратно |
| `docker build -t имя:тег .` · `-f Dockerfile.x` · `--no-cache` · `--target этап` | сборка |
| `docker build --secret id=x,src=файл` | секрет сборки |
| `docker login [реестр]` · `docker logout` | вход и выход |

**Тома и сети**

| Команда | Что делает |
|---|---|
| `docker volume create/ls/inspect/rm имя` | тома |
| `docker network create/ls/inspect/rm имя` | сети |
| `docker network connect/disconnect сеть контейнер` | подключить / отключить |

**Compose**

| Команда | Что делает |
|---|---|
| `docker compose up -d [--build] [сервис]` | создать и запустить |
| `docker compose down [-v]` | остановить и удалить (с томами) |
| `docker compose ps [-a]` · `logs [-f] [сервис]` | состояние · логи |
| `docker compose exec сервис команда` · `run --rm сервис команда` | в работающем · в новом контейнере |
| `docker compose stop/start/restart [сервис]` | без удаления |
| `docker compose config [-q] [--services]` | проверка и итоговая конфигурация |
| `docker compose -f a.yaml -f b.yaml …` · `-p имя` · `--profile имя` | файлы · проект · профиль |
| `docker compose watch` · `docker compose pull` · `docker compose ls` | автообновление · скачать · проекты |

**Dockerfile**

| Инструкция | Для чего |
|---|---|
| `FROM образ:тег [AS этап]` | база и имя этапа |
| `WORKDIR` · `COPY [--from=этап] [--chown=] [--chmod=]` · `ADD` | папка · копирование |
| `RUN` · `RUN --mount=type=cache/secret` | команда при сборке |
| `ENV` · `ARG` · `LABEL` | переменные (рабочие / сборочные), метки |
| `USER` · `EXPOSE` · `VOLUME` · `HEALTHCHECK` · `STOPSIGNAL` | пользователь, порт, том, проверка, сигнал |
| `ENTRYPOINT ["…"]` · `CMD ["…"]` | запуск (всегда exec-форма) |

**Формат `compose.yaml`: основные ключи сервиса**

| Ключ | Для чего |
|---|---|
| `image` / `build` | образ или сборка |
| `ports` · `environment` · `env_file` · `volumes` · `networks` | публикация, переменные, тома, сети |
| `depends_on` + `condition: service_healthy` · `healthcheck` | порядок и готовность |
| `restart` · `mem_limit` · `pids_limit` · `logging` · `stop_grace_period` | эксплуатация |
| `read_only` · `tmpfs` · `cap_drop` · `security_opt` | защита |
| `profiles` · `extends` · `include` · `x-…` · `develop.watch` | переиспользование и разработка |

**Интерполяция:** `${VAR}` · `${VAR:-по_умолчанию}` · `${VAR:?сообщение}` · `$$` — буквальный `$`.
