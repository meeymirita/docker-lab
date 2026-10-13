# Сессия 2 · Контейнеры и жизненный цикл
dur: ~3,5 ч

## 2.1 Жизненный цикл контейнера | short: Жизненный цикл | est: ~30 мин
### intro
**Слова шага:** *состояние контейнера*, *`create`*, *`start`*, *`stop`*, *`rm`*, *`docker run`*.

:::tip Если совсем просто
Контейнер — как игрушка. Собрана (created), играет (running), на паузе (paused), выключена (exited), выброшена (removed). Выключенная игрушка лежит в шкафу и занимает место, пока ты её не выбросишь.
:::

```svg
<svg viewBox="0 0 640 200" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Состояния контейнера" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m4-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m4-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><rect x="10" y="60" width="110" height="52" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="65.0" y="82.0" text-anchor="middle" font-size="13" fill="currentColor">created</text><text x="65.0" y="100.0" text-anchor="middle" font-size="13" fill="currentColor">создан</text><rect x="180" y="60" width="110" height="52" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="235.0" y="82.0" text-anchor="middle" font-size="13" fill="currentColor">running</text><text x="235.0" y="100.0" text-anchor="middle" font-size="13" fill="currentColor">работает</text><rect x="350" y="60" width="110" height="52" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="405.0" y="82.0" text-anchor="middle" font-size="13" fill="currentColor">exited</text><text x="405.0" y="100.0" text-anchor="middle" font-size="13" fill="currentColor">остановлен</text><rect x="520" y="60" width="110" height="52" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="575.0" y="82.0" text-anchor="middle" font-size="13" fill="currentColor">removed</text><text x="575.0" y="100.0" text-anchor="middle" font-size="13" fill="currentColor">удалён</text><line x1="120" y1="86" x2="180" y2="86" stroke="currentColor" stroke-width="1.8" marker-end="url(#m4-e)"/><text x="150.0" y="79.0" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">start</text><line x1="290" y1="86" x2="350" y2="86" stroke="currentColor" stroke-width="1.8" marker-end="url(#m4-e)"/><text x="320.0" y="79.0" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">stop</text><line x1="460" y1="86" x2="520" y2="86" stroke="currentColor" stroke-width="1.8" marker-end="url(#m4-e)"/><text x="490.0" y="79.0" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">rm</text><line x1="350" y1="100" x2="290" y2="100" stroke="currentColor" stroke-width="1.8" stroke-dasharray="5 4" marker-end="url(#m4-e)"/><text x="320" y="128" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">start снова</text><rect x="180" y="140" width="110" height="36" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="235.0" y="163.0" text-anchor="middle" font-size="13" fill="currentColor">paused</text><line x1="215" y1="112" x2="215" y2="140" stroke="currentColor" stroke-width="1.8" marker-end="url(#m4-e)" marker-start="url(#m4-s)"/><text x="205" y="162" text-anchor="end" font-size="12" fill="currentColor" fill-opacity="0.85">pause</text><text x="300" y="162" text-anchor="start" font-size="12" fill="currentColor" fill-opacity="0.85">unpause</text><text x="10" y="22" text-anchor="start" font-size="12" fill="currentColor" fill-opacity="0.85">docker create делает created;</text><text x="10" y="40" text-anchor="start" font-size="12" fill="currentColor" fill-opacity="0.85">docker run = create + start</text></svg>
```

Контейнер не «просто есть» — он проходит через состояния. Знать их нужно, чтобы понимать, что показывает `docker ps` и почему «остановленный» контейнер всё ещё занимает место.


- **created** — контейнер создан (выделены файловая система, имя, настройки), но процесс не запущен.
- **running** — главный процесс работает.
- **paused** — процессы «заморожены» (cgroup freezer), но остаются в памяти.
- **exited** — главный процесс завершился (сам или его остановили). Контейнер лежит на диске вместе с логами и файлами, и его можно запустить заново.
- **removed** — контейнер удалён вместе со своим слоем записи; логи и файлы пропали.

Команда **`docker run`**, с которой ты уже знакома, — это «`create` + `start`» одним движением. Разделим их, чтобы увидеть состояния своими глазами. `--name` задаёт имя контейнера (иначе Docker придумает случайное), а `--format` у `docker ps` оставляет только нужные колонки:

```bash run
docker create --name demo nginx:1.30-alpine
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
```

### result
```out auto
```

`Created` — процесс не запущен. Запустим, заморозим, разморозим, остановим, снова запустим, удалим — и после каждого шага смотрим статус:

```bash run
docker start demo
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
docker pause demo
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
docker unpause demo
docker stop demo
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
```

```out auto
```

Видишь `Up …` (работает), `Up … (Paused)` (заморожен), `Exited (0) …` (остановлен). Теперь удаляем:

```bash run
docker rm demo
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
```

```out auto
```

Таблица пуста — контейнера больше нет. Образ `nginx:1.30-alpine` при этом остался на диске: образ и контейнер живут отдельно (шаг 1.4).

### why
Главная практическая мысль: **остановленный контейнер — не удалённый контейнер**. Он продолжает занимать диск, держать имя (повторный `docker run --name demo` даст конфликт имён) и хранить логи. Поэтому в Docker «остановить» и «удалить» — две разные команды, и привычка убирать за собой (`--rm` или `docker rm`) нужна с первого дня.

### deep Что значит Up и Exited в статусе
`Up 3 seconds` — контейнер работает 3 секунды. `Exited (0) 2 seconds ago` — завершился 2 секунды назад с кодом `0`, то есть успешно; любой другой код — ошибка или сигнал (шаг 2.6). `Created` — ни разу не запускался. `Restarting (1) …` — процесс падает, и политика `restart` пытается поднять его снова (сессия 9).

### deep Если не получилось
- **`Conflict. The container name "/demo" is already in use`** — контейнер с таким именем уже есть (возможно, остановленный). Удали его `docker rm demo` или выбери другое имя.
- **Команда `docker ps` не показывает контейнер** — `docker ps` без `-a` показывает только работающие.

### quiz
- Какие два шага скрыты внутри `docker run`?
- Чем состояние `exited` отличается от «удалён»? Что остаётся на диске?
- Как увидеть остановленные контейнеры?

### links
- https://docs.docker.com/reference/cli/docker/container/ | команды docker container | docker container
- https://docs.docker.com/reference/cli/docker/container/ls/#format | форматирование вывода | docker ps --format

## 2.2 docker run: разбор флагов, порт наружу | short: docker run и флаги | est: ~35 мин
### intro
**Слова шага:** *`-d`*, *`-p host:container`*, *`--name`*, *`--rm`*, *`-e`*, *`-it`*, *foreground/background*.

:::tip Если совсем просто
Порт — номер двери в доме. Запись `-p 8080:80` — табличка на воротах: «Кто стучится в дверь 8080 на улице — проходите в дверь 80 внутри».
:::

```svg
<svg viewBox="0 0 640 160" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Публикация порта: -p 8080:80" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m5-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m5-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><rect x="10" y="50" width="130" height="58" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="75.0" y="75.0" text-anchor="middle" font-size="13" fill="currentColor">Браузер / curl</text><text x="75.0" y="93.0" text-anchor="middle" font-size="13" fill="currentColor">на твоём Mac</text><rect x="210" y="40" width="130" height="78" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="275.0" y="75.0" text-anchor="middle" font-size="13" fill="currentColor">Docker</text><text x="275.0" y="93.0" text-anchor="middle" font-size="13" fill="currentColor">порт 8080 на хосте</text><rect x="410" y="20" width="220" height="118" rx="8" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="520" y="42" text-anchor="middle" font-size="12" font-weight="700" fill="currentColor" fill-opacity="1">контейнер</text><rect x="440" y="62" width="160" height="56" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="520.0" y="86.0" text-anchor="middle" font-size="13" fill="currentColor">nginx слушает</text><text x="520.0" y="104.0" text-anchor="middle" font-size="13" fill="currentColor">порт 80</text><line x1="140" y1="79" x2="210" y2="79" stroke="currentColor" stroke-width="1.8" marker-end="url(#m5-e)"/><text x="175.0" y="72.0" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">:8080</text><line x1="340" y1="79" x2="440" y2="79" stroke="currentColor" stroke-width="1.8" marker-end="url(#m5-e)"/><text x="390.0" y="72.0" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">:80</text><text x="320" y="150" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor" fill-opacity="1">-p  8080 : 80   =   «порт на Mac : порт в контейнере»</text></svg>
```

`docker run` — главная команда Docker. Её общий вид: `docker run [ФЛАГИ] ОБРАЗ [КОМАНДА]`. Всё до имени образа — настройки запуска, всё после — команда, которая запустится *внутри* контейнера вместо стандартной. Самые нужные флаги:

| Флаг | Что делает |
|---|---|
| `-d` (`--detach`) | запустить в фоне и вернуть терминал; без него `docker run` держит терминал, пока контейнер работает (выход — [[Ctrl]]+[[C]]) |
| `--name имя` | своё имя вместо случайного |
| `-p ХОСТ:КОНТЕЙНЕР` | пробросить порт: обращения к порту хоста уходят в порт контейнера |
| `-e ИМЯ=значение` | задать переменную окружения внутри контейнера |
| `--rm` | удалить контейнер сразу после остановки |
| `-i -t` (вместе `-it`) | `-i` держит ввод открытым, `-t` выделяет терминал: можно работать руками, как в `sh` |

Запустим веб-сервер nginx в фоне и откроем его порт на хосте. Внутри контейнера nginx слушает порт 80; мы говорим «порт 8080 на моём компьютере → порт 80 в контейнере»:

```bash run
docker run -d --name web -p 8080:80 nginx:1.30-alpine
```

Docker напечатал длинный идентификатор контейнера — и вернул терминал. Проверим, что сайт отвечает. `curl` — программа-браузер для терминала: `-s` убирает индикатор прогресса, `-o /dev/null` отбрасывает тело, `-w` печатает код ответа:

```bash run
sleep 2   # nginx нужна секунда на запуск
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080
curl -s http://localhost:8080 | head -5
```

### result
```out auto
```

`200` — страница отдана. Откуда на твоём Mac взялся `localhost:8080`? Пробросом занимается Docker: он слушает порт 8080 на хосте и передаёт соединения в сеть контейнера, на порт 80. Слева от двоеточия — порт **хоста**, справа — порт **контейнера**: `-p 8080:80`. Откроешь в браузере `http://localhost:8080` — увидишь страницу «Welcome to nginx!».

Что будет, если порт хоста занят? Попробуем запустить второй контейнер на тот же 8080:

```bash run
docker run -d --name web2 -p 8080:80 nginx:1.30-alpine
```

```out auto
```

Читай справа налево: `port is already allocated` — порт 8080 уже кем-то занят (нашим `web`). Docker создал контейнер `web2`, но не смог запустить; убери его и выбери другой порт слева:

```bash run
docker rm web2
docker run -d --name web2 -p 8081:80 nginx:1.30-alpine
sleep 2
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8081
```

```out auto
```

Теперь два сервера живут рядом: один на 8080, другой на 8081, а внутри оба слушают 80 — у каждого контейнера своя сеть (шаг 1.5).

### why
Запомни порядок: **`-p` — порт хоста слева, порт контейнера справа**. Путаница между ними — самая частая ошибка с портами. И второе: порт **не пробрасывается сам**. Контейнер, который слушает 80, снаружи недоступен, пока не добавлен `-p`.

### deep Команда по частям
`docker run -d --name web -p 8080:80 nginx:1.30-alpine`: `-d` — фон; `--name web` — имя; `-p 8080:80` — пробросить; `nginx:1.30-alpine` — образ и тег (nginx версии 1.30 на Alpine, шаг 3.4). Команды после образа нет, поэтому запустилась команда по умолчанию, записанная в образе (сессия 4).

### deep Как ещё можно
- **Опубликовать только на своём компьютере:** `-p 127.0.0.1:8080:80` — порт откроется лишь для самого Mac, а не для всей сети (важно для баз данных).
- **Выбрать порт автоматически:** `-P` (большая) — Docker сам выберет свободный порт хоста; какой именно — покажет `docker port web`.
- **Запустить на переднем плане:** без `-d` терминал занят контейнером, а логи идут прямо в него; остановка — [[Ctrl]]+[[C]].
- **Посмотреть проброшенные порты:** `docker port web`.

### deep Если не получилось
- **`port is already allocated`** — порт хоста занят другим контейнером или программой. Найди контейнер: `docker ps`; программу на Mac: `lsof -i :8080`.
- **`curl: (7) Failed to connect`** — забыла `-p`, перепутала порты местами, или контейнер ещё не успел стартовать (подожди секунду). Проверь `docker ps` (колонка `PORTS`) и `docker logs web`.
- **На Mac порт 5000 или 7000 «уже занят»** — их занимает системный AirPlay-приёмник; выбери другой порт.

### quiz
- Что стоит слева, а что справа в `-p 8080:80`?
- Почему два контейнера могут оба слушать порт 80 внутри себя, но не могут оба занять порт 8080 на хосте?
- Что делает флаг `-d` и чем отличается запуск без него?

### links
- https://docs.docker.com/reference/cli/docker/container/run/ | справочник docker run | docker run
- https://docs.docker.com/engine/network/port-publishing/ | публикация портов | Port publishing

## 2.3 ps, stop, kill, rm, restart | short: Управление контейнерами | est: ~30 мин
### intro
**Слова шага:** *`ps`*, *`stop`*, *`kill`*, *`restart`*, *`rm -f`*, *SIGTERM*, *SIGKILL*.

:::tip Если совсем просто
`stop` — вежливо сказать «пора заканчивать, собирайся». `kill` — выдернуть вилку из розетки. Вежливо лучше: человек успеет убрать за собой.
:::

Два контейнера уже работают (`web` и `web2`). Научимся ими управлять. `docker ps` показывает работающие, `docker ps -a` — все. Колонки: `CONTAINER ID` (короткий идентификатор), `IMAGE`, `COMMAND` (главный процесс), `CREATED`, `STATUS`, `PORTS`, `NAMES`.

```bash run
docker ps
```

### result
```out auto
```

В любой команде контейнер можно называть по имени (`web`) или по началу идентификатора (первые 3–4 символа, пока они однозначны).

**`docker stop`** останавливает «вежливо»: шлёт процессу сигнал **SIGTERM** («пора заканчивать») и ждёт до 10 секунд, чтобы тот успел закрыть соединения и сохраниться; если не успел — шлёт **SIGKILL** («немедленно»), который нельзя перехватить. **`docker kill`** отправляет SIGKILL сразу. **`docker restart`** — stop и потом start.

```bash run
docker stop web2
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker start web2
docker restart web2
docker ps --format 'table {{.Names}}\t{{.Status}}'
```

```out auto
```

Заметь: после `stop` порт исчез из `PORTS`, а после `start` вернулся тот же `8081`, потому что настройки контейнера сохраняются. Теперь жёсткий вариант и удаление. `docker rm` удаляет остановленный контейнер; работающий отказывается удалить, пока не добавишь `-f` (force — остановить и удалить):

```bash run
docker rm web2
docker kill web2
docker rm -f web2
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
```

```out auto
```

Первая команда пожаловалась (`cannot remove container … container is running: stop the container before removing or force remove`) — контейнер ещё работал; `kill` остановил его мгновенно; `rm -f` убрал. (Если команда дала ошибку, остальные всё равно выполнились — оболочка не останавливается на ошибке.)

### why
Различие `stop` и `kill` — не придирка: **`stop` даёт программе шанс закончить работу аккуратно** (записать данные, закрыть соединение с базой), а `kill` — нет. В продакшне почти всегда нужен `stop`; `kill` — когда программа не отвечает. Дальше (шаг 2.6) мы увидим, что `stop` бывает неэффективным, если программа не слушает SIGTERM.

### deep Как ещё можно
- **Несколько контейнеров за раз:** `docker stop web web2 db`.
- **Все работающие:** `docker stop $(docker ps -q)` (`-q` — только идентификаторы). На твоём Mac это остановит и контейнеры других проектов — используй осторожно!
- **Подождать дольше или короче:** `docker stop -t 30 web` — ждать 30 секунд до SIGKILL.
- **Свой сигнал:** `docker kill --signal=HUP web` (многие серверы по HUP перечитывают конфиг).

### deep Если не получилось
- **`Error response from daemon: cannot remove container … container is running`** — контейнер работает; добавь `-f` или сперва `docker stop`.
- **`No such container: web2`** — уже удалён или опечатка в имени; `docker ps -a` покажет, что есть.

### quiz
- Чем `docker stop` отличается от `docker kill`?
- Что произойдёт с контейнером после `docker stop`, а потом `docker start`? Сохранятся ли настройки?
- Как удалить работающий контейнер одной командой?

### links
- https://docs.docker.com/reference/cli/docker/container/stop/ | docker stop | docker stop

## 2.4 logs, exec, attach, cp | short: Логи и вход внутрь | est: ~35 мин
### intro
**Слова шага:** *`logs`*, *`exec`*, *`attach`*, *`cp`*, *stdout/stderr*, *`-it`*.

:::tip Если совсем просто
`logs` — дневник, который контейнер ведёт сам. `exec` — зайти в комнату и поговорить. `cp` — передать записку или файл.
:::

Контейнер работает — как понять, что он делает? Всё, что главный процесс печатает в стандартный вывод (stdout) и вывод ошибок (stderr), Docker собирает как **логи** контейнера. Почему nginx пишет логи в консоль, а не в файл — потому что так принято для контейнеров: логи забирает Docker.

Сделаем запрос к `web`, чтобы в логе что-то появилось, и прочитаем его. `--tail 3` — последние три строки:

```bash run
curl -s -o /dev/null http://localhost:8080/hello-page
docker logs --tail 3 web
```

### result
```out auto
```

Видны две записи о запросе `GET /hello-page`: в access-логе он с кодом `404` (такой страницы нет) — это классический формат, а в error-логе — подробность `No such file or directory`. Полезные флаги `docker logs`: `-f` (follow — следить за новыми строками, выход [[Ctrl]]+[[C]]), `--since 10m` (за последние 10 минут), `--tail N`, `-t` (с отметками времени).

**`docker exec`** запускает *ещё одну* команду внутри **уже работающего** контейнера. Это не новый контейнер, а дополнительный процесс в том же. Версия nginx и список файлов сайта:

```bash run
docker exec web nginx -v
docker exec web ls /usr/share/nginx/html
```

```out auto
```

Чтобы «зайти внутрь» и работать руками, нужны `-it` (шаг 2.2): `docker exec -it web sh` откроет оболочку в контейнере. Выход — `exit`. (Здесь это не показано: в методичке нет терминала, у тебя он есть — попробуй!)

**`docker attach`** — другое: он присоединяет твой терминал к *главному процессу* (PID 1), а не создаёт новый. Для nginx это почти бесполезно (главный процесс ничего не читает), и опасно: [[Ctrl]]+[[C]] в attach остановит сам главный процесс — а с ним и контейнер. Отсоединиться, не остановив: [[Ctrl]]+[[P]], затем [[Ctrl]]+[[Q]]. Для повседневной работы почти всегда нужен `exec`, а не `attach`.

**`docker cp`** копирует файлы между хостом и контейнером в обе стороны (`docker cp ИСТОЧНИК ЦЕЛЬ`; контейнерный путь пишется как `имя:путь`). Заберём конфиг nginx из контейнера на хост и положим туда свою страницу:

```bash run
mkdir -p ~/docker-lab/s02 && cd ~/docker-lab/s02
docker cp web:/etc/nginx/conf.d/default.conf ./default.conf
head -4 default.conf
echo '<h1>Привет из моего файла</h1>' > index.html
docker cp index.html web:/usr/share/nginx/html/index.html
curl -s http://localhost:8080
```

```out auto
```

Страница заменилась: мы положили свой `index.html` прямо в работающий контейнер. Но это изменение живёт только в слое записи именно этого контейнера — пересоздашь контейнер, и страница вернётся прежняя (шаг 2.5 покажет это через `diff`, сессия 7 — как делать правильно через тома).

### why
Эти четыре команды — ежедневная работа. `logs` отвечает на «что происходит», `exec` — на «что внутри», `cp` — на «как передать файл». Привыкни сначала смотреть `docker logs`: в девяти случаях из десяти причина падения или странного поведения написана там.

### deep Команда по частям
`docker logs --tail 3 web`: `logs` — показать логи; `--tail 3` — только три последние строки; `web` — имя контейнера. Docker хранит логи в JSON-файлах на диске VM (драйвер `json-file`, шаг 1.3 `Logging Driver`); без ограничения они растут бесконечно — лимиты задаются в Compose (сессия 9).

### deep Если не получилось
- **`docker logs` пуст** — приложение пишет логи в файл, а не в stdout. В образах-«с открыткой» вроде nginx это решено ссылкой `/var/log/nginx/access.log → /dev/stdout`; в своих приложениях пиши в stdout/stderr.
- **`OCI runtime exec failed … executable file not found`** — в образе нет такой программы (в Alpine нет `bash` — используй `sh`).
- **`Error: No such container:path`** — в `docker cp` забыла двоеточие или имя контейнера.

### quiz
- Откуда `docker logs` берёт текст и почему приложению стоит писать в stdout?
- Чем `docker exec` отличается от `docker attach`?
- Почему файл, скопированный `docker cp` в контейнер, может «пропасть» после пересоздания контейнера?

### links
- https://docs.docker.com/reference/cli/docker/container/logs/ | docker logs | docker logs
- https://docs.docker.com/reference/cli/docker/container/exec/ | docker exec | docker exec
- https://docs.docker.com/reference/cli/docker/container/cp/ | docker cp | docker cp

## 2.5 inspect, stats, top, events, diff | short: Осмотр контейнера | est: ~35 мин
### intro
**Слова шага:** *`inspect`*, *`--format`*, *`stats`*, *`top`*, *`events`*, *`diff`*, *Go-шаблон*.

:::tip Если совсем просто
`inspect` — медицинская карта контейнера. `stats` — пульсометр. `diff` — вопрос «Что ты здесь поменял с тех пор, как тебя собрали?».
:::

Пять команд-«рентгенов». Все работают с уже запущенным контейнером `web`.

**`docker inspect`** выдаёт полное описание контейнера в JSON — всё, что Docker о нём знает. Читать его целиком тяжело, поэтому используют `--format` с **Go-шаблоном** `{{…}}`: выбираешь только нужные поля.

```bash run
docker inspect --format '{{.State.Status}} (код выхода {{.State.ExitCode}})' web
docker inspect --format '{{.Config.Image}}' web
docker inspect --format '{{json .Config.Env}}' web
docker inspect --format '{{json .NetworkSettings.Ports}}' web
```

### result
```out auto
```

Первая строка — состояние и код выхода, вторая — образ, третья — переменные окружения (`json` печатает структуру как JSON), четвёртая — проброшенные порты (`HostPort` — порт хоста). Путь в шаблоне повторяет вложенность JSON: сначала загляни в `docker inspect web | head -50`, найди нужный ключ, потом пиши `.Ключ.Вложенный`.

**`docker stats`** — потребление ресурсов в реальном времени (без `--no-stream` обновляется непрерывно; выход — [[Ctrl]]+[[C]]). **`docker top`** — процессы внутри контейнера (глазами хоста):

```bash run
docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.PIDs}}'
docker top web
```

```out auto
```

`MemUsage` — сколько памяти занято / какой лимит (если лимита нет, показан весь объём VM). `top` показывает мастер-процесс nginx и рабочие процессы.

**`docker diff`** показывает, что изменилось в файловой системе контейнера по сравнению с образом: `A` — добавлен файл, `C` — изменён, `D` — удалён. Это «улики» слоя записи:

```bash run
docker diff web
```

```out auto
```

В списке видны наш `index.html` (мы подменили его в шаге 2.4) и служебные файлы nginx. Всё это — слой записи контейнера, и он исчезнет вместе с ним.

**`docker events`** — журнал событий демона: создание, старт, остановка, удаление. Покажем последние несколько (`--since 10m` — за последние 10 минут, `--until 0s` — до настоящего момента, чтобы команда завершилась, а не ждала новых):

```bash run
docker events --since 10m --until 0s --filter container=web2 --format '{{.Action}}'
```

```out auto
```

Это записанная история всех контейнеров с именем `web2`, начиная с неудачной попытки на порту 8080 (первая пара `create`/`destroy`). Дальше по порядку шага 2.3: `create` и `start` (запуск), `kill`, `stop` и `die` (остановка: сигнал, команда, завершение процесса), второй `start`, `restart` (в нём внутри те же `kill`, `die`, `start`), и в конце `kill`, `die` и `destroy` (удалён). При поиске причины «почему контейнер упал и когда» `docker events` бывает единственным свидетелем.

### why
`inspect` — единственный полный источник правды о контейнере; многие «загадки» (не тот образ, не та переменная, не тот порт) решаются одним `--format`. `diff` же честно показывает главную особенность контейнера: **всё, что ты меняешь внутри, лежит в отдельном слое записи и пропадёт вместе с контейнером** — это и есть причина, почему данные хранят в томах.

### deep Команда по частям
`docker inspect --format '{{json .Config.Env}}' web`: `.Config.Env` — путь к полю «переменные окружения» в JSON; `json` — функция шаблона, печатающая значение как JSON (без неё Go показал бы «сырой» вид структуры); `web` — имя. Кавычки одинарные, чтобы оболочка не трогала `{{ }}`.

### deep Как ещё можно
- **Свод по всем контейнерам:** `docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'`.
- **IP-адрес в сети:** `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web`.
- **Красивый JSON:** `docker inspect web | jq '.[0].State'` (если установлен `jq`).
- **Графика:** вкладка *Containers* в Docker Desktop показывает те же логи, статистику и «Inspect».

### deep Если не получилось
- **`template parsing error: … can't evaluate field`** — опечатка в пути; сравни с `docker inspect web`.
- **`docker stats` показывает `--`** — контейнер остановлен.
- **Пустой вывод `events`** — события старше `--since` или в другом диапазоне; расширь окно (`--since 1h`).

### quiz
- Как получить из `docker inspect` только IP-адрес или только переменные окружения?
- Что показывает `docker diff` и почему важно знать, что там написано?
- Чем `docker stats` отличается от `docker top`?

### links
- https://docs.docker.com/reference/cli/docker/inspect/ | docker inspect | docker inspect
- https://docs.docker.com/engine/cli/formatting/ | форматирование вывода | Format command output

## 2.6 Переменные окружения, сигналы, коды выхода | short: Окружение и сигналы | est: ~40 мин
### intro
**Слова шага:** *переменная окружения*, *`-e`*, *`--env-file`*, *PID 1*, *SIGTERM*, *код выхода*, *137*, *143*.

:::tip Если совсем просто
Переменные окружения — записки на двери: «Сегодня работаем до шести». Сигнал — это когда ты говоришь вслух «Заканчивай!». Если человек в наушниках (процесс без обработчика), он не услышит, и придётся выключать свет (SIGKILL) — отсюда код 137.
:::

**Переменная окружения** — именованное значение, которое процесс получает от родителя. Через них в контейнеры передают настройки: адрес базы, пароль, режим работы. Образ один, а настройки при запуске разные.

```bash run
docker run --rm -e GREETING=привет -e NAME=Мира alpine sh -c 'echo "$GREETING, $NAME"'
```

```out auto
```

Когда переменных много, их кладут в файл `ИМЯ=значение` по строке и передают `--env-file`. Важно: в таком файле **нельзя писать комментарии на строке со значением** (`A=1  # заметка` — значение станет `1  # заметка`):

```bash run
cd ~/docker-lab/s02
printf 'GREETING=добрый день\nNAME=гость\n' > app.env
docker run --rm --env-file app.env alpine sh -c 'echo "$GREETING, $NAME"'
```

```out auto
```

Теперь сигналы. Мы видели: `docker stop` шлёт SIGTERM и через 10 секунд — SIGKILL. Но сигнал получает **процесс с PID 1**, и ядро относится к нему особо: если программа сама не повесила обработчик SIGTERM, этот сигнал для PID 1 **игнорируется**. Проверим на программе `sleep`, которая обработчика не ставит. Замерим время остановки (`time` — встроенная команда оболочки, печатает, сколько прошло):

```bash run
docker run -d --name sleeper alpine sleep 1000
time docker stop sleeper
docker inspect --format 'код выхода: {{.State.ExitCode}}' sleeper
```

### result
```out auto
```

`stop` провисел ровно 10 секунд (`real 0m10…`) и закончился кодом **137**. Разберём: Docker послал SIGTERM, `sleep` его проигнорировал (PID 1 без обработчика), через 10 секунд пришёл SIGKILL — процесс убит. Код выхода по соглашению Linux при смерти от сигнала равен **128 + номер сигнала**: SIGKILL — это сигнал 9, итого **137**; SIGTERM — сигнал 15, итого **143**. Проверим арифметику на процессе, который умирает от SIGTERM по-настоящему (в `sh -c` запускаем `sleep` в фоне и убиваем его `kill -TERM`, а `$?` показывает его код):

```bash run
docker run --rm alpine sh -c 'sleep 100 & kill -TERM $!; wait $!; echo "код: $?"'
```

```out auto
```

`143` = 128 + 15. (Слово `Terminated` — сообщение самой оболочки о том, что дочерний процесс убит сигналом.) Теперь для сравнения остановим nginx — он сам обрабатывает SIGTERM и завершается корректно:

```bash run
time docker stop web
docker inspect --format 'код выхода: {{.State.ExitCode}}' web
```

```out auto
```

Мгновенно и с кодом `0`. Так выглядит программа, которая «вежливо» реагирует на `stop`. В сессии 4 мы увидим, как записать `CMD` в `Dockerfile`, чтобы SIGTERM доходил до приложения, а не терялся в оболочке.

### why
Код 137 в логах CI и в `docker ps -a` — самая частая «загадка» для новичков: «контейнер убили». Теперь ты знаешь два типичных источника: либо ты (или система) прислали SIGKILL — `docker stop` по тайм-ауту, `docker kill`, — либо ядро убило процесс за превышение памяти (OOM). Различить помогает `docker inspect` (поле `State.OOMKilled`).

### deep Как ещё можно
- **Передать переменную из своего окружения:** `docker run -e HOME alpine …` (без `=значение` берётся значение из твоей оболочки).
- **Посмотреть, что внутри:** `docker run --rm alpine env`.
- **Не передавай пароли в командной строке** без необходимости: они видны в `docker inspect` и в истории оболочки. Лучше `--env-file` с правами `600`, а позже — секреты (сессия 8).

### deep Таблица кодов выхода
`0` — успешно. `1` — общая ошибка приложения. `2` — неверное использование команды. `125` — сам `docker run` не смог запуститься. `126` — команда найдена, но её нельзя выполнить (права). `127` — команда не найдена. `137` — SIGKILL (128+9): убили, часто из-за памяти или тайм-аута `stop`. `143` — SIGTERM (128+15): вежливо остановили.

### deep Если не получилось
- **Значение переменной с пробелом** — в `-e` бери кавычки: `-e "GREETING=добрый день"`.
- **В `--env-file` значение вместе с комментарием** — убери комментарий со строки значения.
- **`stop` не 10 секунд, а мгновенно** — у программы есть обработчик SIGTERM (как у nginx), и это нормально.

### quiz
- Почему `docker stop sleeper` занял десять секунд и закончился кодом 137?
- Что означает код выхода `143` и как его посчитать?
- Почему нельзя писать комментарий в строке значения в `--env-file`?

### links
- https://docs.docker.com/reference/cli/docker/container/run/#env | переменные окружения | docker run --env
- https://docs.docker.com/engine/containers/run/#exit-status | коды выхода | Exit status

## 2.7 🔨 Сломать → починить: контейнер стартует и сразу Exited | short: Сразу Exited | est: ~30 мин
### intro
**Слова шага:** *долгоживущий процесс*, *`Exited (0)`*, *`Exited (1)`*, *`docker logs`*.

:::tip Если совсем просто
Контейнер живёт, пока работает его главный жилец. Жилец ушёл — квартиру закрыли. Если ушёл из-за ошибки, он оставил записку: читай `docker logs`.
:::

Самый частый вопрос в Docker: «я запустил контейнер, а он тут же остановился». Контейнер живёт, пока жив его главный процесс. Если процесс закончился — закончился и контейнер. Воспроизведём два типичных случая.

**Случай 1: процесс сразу завершается.**

```bash run
docker run -d --name quick alpine echo "я отработал"
sleep 1
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
docker logs quick
```

### result
```out auto
```

`Exited (0)` — это не ошибка: `echo` напечатал фразу и закончил, поэтому контейнер остановился «вовремя». Починка зависит от цели: если нужен постоянный сервис — запускай долгоживущую программу (веб-сервер, а не `echo`); если задача одноразовая — всё так и задумано.

**Случай 2: приложение падает с ошибкой.** Запустим PostgreSQL «как есть», без пароля (образ `postgres:18` скачается, это 150–200 МБ):

```bash run
docker run -d --name pg postgres:18
sleep 3
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
docker logs pg
```

```out auto
```

Теперь `Exited (1)`: код `1` — ошибка. Алгоритм диагностики один и тот же всегда: **1)** `docker ps -a` — в каком состоянии и с каким кодом; **2)** `docker logs` — что приложение само написало перед смертью. Здесь написано прямо: `Database is uninitialized and superuser password is not specified` — не задан пароль суперпользователя. Образ PostgreSQL требует переменную `POSTGRES_PASSWORD`. Чиним: удалим сломанный контейнер и запустим с паролем (`--rm` удалит контейнер при остановке, а флаг `-v` у `rm` в конце — вместе с анонимным томом данных, который создал образ):

```bash run
docker rm pg
docker run -d --name pg -e POSTGRES_PASSWORD=secret postgres:18
sleep 5
docker ps --format 'table {{.Names}}\t{{.Status}}'
docker exec pg psql -U postgres -c 'select version();'
```

```out auto
```

База работает: `Up …` и версия PostgreSQL. Заметь, как поменялся алгоритм: **причину мы не гадали — мы её прочитали**. Это и есть главный навык лабы.

Уберём за собой всё, что создали в этой сессии (`-f` — удалить даже работающие, `-v` — вместе с томами, созданными контейнерами):

```bash run
docker rm -fv pg quick web sleeper
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
```

```out auto
```

### why
Привычка «сначала `ps -a`, потом `logs`» экономит часы. Почти ни одна поломка контейнера не требует догадок: приложение само пишет причину в логи. Если логов нет — значит, процесс упал раньше, чем успел что-то сказать, и надо смотреть код выхода и `docker inspect`.

### deep Если не получилось
- **`Exited (126)` или `(127)`** — команда в образе не найдена или не выполняется; проверь написание команды после имени образа.
- **`Exited (137)` почти сразу** — вероятно, мало памяти у VM (шаг 1.3): увеличь в Settings → Resources или проверь `OOMKilled`:
  `docker inspect --format '{{.State.OOMKilled}}' имя`.
- **`psql: error: connection … No such file or directory`** — PostgreSQL ещё запускается; подожди несколько секунд (в сессии 8 мы научимся ждать готовности правильно).

### deep Как ещё можно
Если контейнер падает так быстро, что логи не успевают прочитаться, запусти его с другой командой и посмотри изнутри: `docker run --rm -it --entrypoint sh образ`. Это обходит штатный запуск и открывает оболочку (подробно про `ENTRYPOINT` — сессия 4).

### quiz
- Почему `docker run -d alpine echo привет` приводит к `Exited (0)`, и это не ошибка?
- Какие две команды ты запускаешь первыми, когда контейнер остановился сам?
- Что означал код `1` у `postgres:18` и где была написана причина?

### outro
:::tip Приёмка сессии 2
- Ты можешь запустить `nginx` в фоне с пробросом порта и получить его страницу через `curl` или браузер.
- Ты отличаешь `stop` от `kill` и можешь объяснить, почему `docker stop` бывает медленным и заканчивается кодом 137.
- Ты читаешь `docker logs`, заходишь `docker exec`, копируешь файлы `docker cp` и смотришь `docker inspect --format`.
- Ты находишь по `docker ps -a` и `docker logs` причину, почему контейнер завершился, и починила `postgres` добавлением пароля.
- Ты убираешь за собой по имени, а не `prune`.
:::
