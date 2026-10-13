# Сессия 6 · Сети
dur: ~3,5 ч

## 6.1 У каждого контейнера своя сеть | short: Модель сети | est: ~30 мин
### intro
**Слова шага:** *сетевой стек*, *сетевой интерфейс*, *IP-адрес*, *сеть bridge*, *шлюз*, *`docker network ls`*.

:::tip Если совсем просто
Каждый контейнер живёт в своей комнате со своим телефоном и своим номером. Чтобы контейнеры могли звонить друг другу, Docker строит внутри компьютера маленький «коммутатор» — **сеть bridge** — и подключает все телефоны к нему. Номера у них выдаёт сам Docker.
:::

Вспомни шаг 1.5: у каждого контейнера своё пространство имён `net` — **свой сетевой стек**: свои интерфейсы, свои адреса, свои порты и даже свой `localhost`. Контейнер не видит сеть хоста и соседей, пока ты не подключишь его к общей сети.

Docker создаёт виртуальные сети (драйвер **bridge**) — это «виртуальный коммутатор» внутри хоста. Контейнеры, подключённые к одной сети, получают в ней IP-адреса и могут обращаться друг к другу. Посмотрим, какие сети есть из коробки:

```bash run
docker network ls
```

### result
```out auto
```

Три сети есть всегда: **`bridge`** (сеть по умолчанию для всех новых контейнеров), **`host`** (контейнер использует сетевой стек самого хоста) и **`none`** (никакой сети). Подключим два контейнера к сети по умолчанию и посмотрим их адреса. `sleep 300` просто «держит» контейнер живым:

```bash run
docker run -d --name n1 alpine:3.22 sleep 300
docker run -d --name n2 alpine:3.22 sleep 300
docker inspect --format 'n1: {{.NetworkSettings.Networks.bridge.IPAddress}}' n1
docker inspect --format 'n2: {{.NetworkSettings.Networks.bridge.IPAddress}}' n2
```

```out auto
```

Каждому выдан адрес из подсети сети `bridge` (обычно `172.17.0.0/16`). Проверим связь: `n1` «звонит» по IP на `n2` (`ping -c 2` отправляет два пакета). Адрес `n2` подставляем автоматически:

```bash run
IP2=$(docker inspect --format '{{.NetworkSettings.Networks.bridge.IPAddress}}' n2)
docker exec n1 ping -c 2 "$IP2"
docker exec n1 ip -o addr show eth0
```

```out auto
```

Пинг идёт, а у `n1` свой интерфейс `eth0` со своим адресом — это «конец» виртуального кабеля, который идёт к коммутатору `bridge` на хосте. Но обрати внимание: мы звонили **по номеру**. Попробуем по имени:

```bash run
docker exec n1 ping -c 1 n2
```

```out auto
```

`bad address 'n2'` — в сети по умолчанию Docker **не умеет находить контейнеры по имени**. Это главная причина, зачем нужны свои сети (шаг 6.3). Уберём контейнеры:

```bash run
docker rm -f n1 n2
```

```out auto
```

```svg
<svg viewBox="0 0 640 235" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Сеть bridge по умолчанию и пользовательская сеть" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m1-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m1-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><rect x="10" y="30" width="290" height="170" rx="8" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="155" y="22" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor" fill-opacity="1">bridge по умолчанию (docker0)</text><rect x="30" y="60" width="110" height="44" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="85.0" y="78.0" text-anchor="middle" font-size="12" fill="currentColor">контейнер A</text><text x="85.0" y="96.0" text-anchor="middle" font-size="12" fill="currentColor">172.17.0.2</text><rect x="170" y="60" width="110" height="44" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="225.0" y="78.0" text-anchor="middle" font-size="12" fill="currentColor">контейнер B</text><text x="225.0" y="96.0" text-anchor="middle" font-size="12" fill="currentColor">172.17.0.3</text><line x1="140" y1="82" x2="170" y2="82" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)" marker-start="url(#m1-s)"/><text x="155" y="135" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.9">по IP — видят друг друга</text><text x="155" y="155" text-anchor="middle" font-size="12" font-weight="700" fill="currentColor" fill-opacity="1">по имени — НЕТ DNS</text><text x="155" y="178" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">ping B → «bad address»</text><rect x="340" y="30" width="290" height="170" rx="8" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="485" y="22" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor" fill-opacity="1">своя сеть (coffee-net)</text><rect x="360" y="60" width="110" height="44" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="415.0" y="78.0" text-anchor="middle" font-size="12" fill="currentColor">api</text><text x="415.0" y="96.0" text-anchor="middle" font-size="12" fill="currentColor">172.18.0.2</text><rect x="500" y="60" width="110" height="44" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="555.0" y="78.0" text-anchor="middle" font-size="12" fill="currentColor">db</text><text x="555.0" y="96.0" text-anchor="middle" font-size="12" fill="currentColor">172.18.0.3</text><line x1="470" y1="82" x2="500" y2="82" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)" marker-start="url(#m1-s)"/><text x="485" y="135" text-anchor="middle" font-size="12" font-weight="700" fill="currentColor" fill-opacity="1">видят друг друга по ИМЕНИ</text><text x="485" y="155" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.9">встроенный DNS Docker</text><text x="485" y="178" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">wget http://api:3000 работает</text></svg>
```

### why
Сеть — это ещё один слой изоляции, как файловая система или процессы: по умолчанию контейнер сидит в своей «комнате». Понимание, что у каждого контейнера свой `localhost`, объясняет самую частую ошибку: приложение в контейнере обращается к `localhost:5432`, а база — в другом контейнере, и `localhost` ведёт в **пустоту внутри самого этого контейнера**.

### deep Команда по частям
`docker exec n1 ping -c 2 "$IP2"`: `exec` — выполнить команду в работающем контейнере `n1`; `ping -c 2` — отправить два пакета; `"$IP2"` — значение переменной (адрес `n2`), подставленное оболочкой **до** запуска Docker. `ip -o addr show eth0` — адреса интерфейса `eth0` в одну строку.

### deep Как ещё можно
- **Подсеть сети:** `docker network inspect bridge --format '{{json .IPAM.Config}}'`.
- **Глазами хоста:** на Linux хост видит интерфейс `docker0` и по одному `veth…` на контейнер; на Mac всё это спрятано в VM Docker Desktop.
- **Адрес по умолчанию (`172.17.0.0/16`)** может пересекаться с корпоративной сетью или VPN — подсеть меняют в `daemon.json` (`default-address-pools`).

### deep Если не получилось
- **`ping: not found`** — в образе нет `ping`; в Alpine он есть, в minimal/distroless — нет.
- **`bad address 'n2'`** — так и должно быть в сети по умолчанию; смотри шаг 6.3.
- **`Cannot connect`/нет адреса** — контейнер завершился; `docker ps -a` покажет.

### quiz
- Что значит «у контейнера свой `localhost`»?
- Какие сети есть в Docker по умолчанию и чем они отличаются?
- Почему в сети `bridge` по умолчанию `ping n2` не работает, а `ping 172.17.0.3` — работает?

### links
- https://docs.docker.com/engine/network/ | сети Docker | Networking overview
- https://docs.docker.com/engine/network/drivers/bridge/ | драйвер bridge | Bridge network driver

## 6.2 Порты: -p, NAT, EXPOSE | short: Публикация портов | est: ~35 мин
### intro
**Слова шага:** *публикация порта*, *`-p`*, *NAT*, *`127.0.0.1:…`*, *`-P`*, *`EXPOSE`*, *`docker port`*.

:::tip Если совсем просто
Контейнер сидит в закрытой комнате. Чтобы к нему мог пройти гость с улицы, на воротах ставят **табличку-указатель**: «стучите в дверь 8080, вас проводят в комнату номер 80». Это и есть `-p 8080:80`. Без таблички гость может хоть кричать — его не услышат.
:::

В шаге 2.2 мы использовали `-p 8080:80` как формулу. Теперь разберём, что за ней. Когда ты публикуешь порт, Docker **на хосте** настраивает правило трансляции адресов (**NAT**): всё, что приходит на порт хоста 8080, перенаправляется на IP контейнера, порт 80. Правило живёт, пока жив контейнер.

Три главных формы:

- **`-p 8080:80`** — порт 8080 хоста (на **всех** адресах хоста) → порт 80 контейнера.
- **`-p 127.0.0.1:8080:80`** — то же, но только для самого хоста: из сети снаружи порт недоступен. Для баз данных и админок на разработке это важно: пароль у них часто простой.
- **`-P`** (большая) — публикует все порты, объявленные в `EXPOSE`, на **случайные** свободные порты хоста.

И частое заблуждение: **`EXPOSE` не открывает порт**. Это только запись в образе («этот сервис слушает 3000»), удобная для людей и для `-P`. Проверим наш API (в Dockerfile у него `EXPOSE 3000`) без публикации и с ней. Сначала без:

```bash run
docker run -d --name p0 coffee-api:slim
sleep 2
docker port p0 || echo "порты не опубликованы"
curl -s -m 2 http://localhost:3000/health || echo "curl: порт 3000 хоста не отвечает"
```

### result
```out auto
```

`docker port` ничего не показал, а `curl` не достучался: `EXPOSE` не сделал порт доступным. Теперь с `-P` и с явным `-p`, на разных адресах. `PORTS` в `docker ps` показывает всё:

```bash run
docker run -d --name p1 -P coffee-api:slim
docker run -d --name p2 -p 127.0.0.1:3022:3000 coffee-api:slim
docker run -d --name p3 -p 3033:3000 coffee-api:slim
sleep 2
docker ps --format 'table {{.Names}}\t{{.Ports}}' | grep -E 'NAMES|p1|p2|p3'
docker port p1
```

```out auto
```

Расшифровка колонки `PORTS`: `p1` — `0.0.0.0:32768->3000/tcp`: Docker выбрал случайный порт хоста (диапазон 32768+) и проложил путь к 3000 контейнера (`-P`); `p2` — `127.0.0.1:3022->3000/tcp`: порт слушает только петлевой адрес хоста; `p3` — `0.0.0.0:3033->3000/tcp`: открыт на всех адресах. (Запись `[::]:…` — то же самое для IPv6.) Проверим доступ к `p3`:

```bash run
curl -s -w '\n' http://localhost:3033/health
docker rm -f p0 p1 p2 p3
```

```out auto
```

### why
Правило: **что-то снаружи должно достучаться — публикуй порт; что-то внутри только для соседей — не публикуй вовсе**. Базу данных почти никогда не публикуют (её видят другие контейнеры по сети, шаг 6.3), а если очень нужно показать на разработке — через `127.0.0.1:…`. Открытый на `0.0.0.0` порт Postgres с паролем `secret` на сервере — классический способ взлома.

### deep Как ещё можно
- **UDP:** `-p 5353:53/udp`.
- **Диапазон:** `-p 8000-8010:8000-8010`.
- **В Compose:** `ports: ["127.0.0.1:5432:5432"]` — те же формы (сессия 8).
- **Почему `localhost` работает на Mac:** Docker Desktop сам пробрасывает порт из VM на твой Mac.

### deep Если не получилось
- **`port is already allocated`** — этот порт хоста уже занят (шаг 2.2).
- **Снаружи (с другого компьютера) не открывается, а `localhost` работает** — порт привязан к `127.0.0.1`, либо файрвол.
- **`curl: (52) Empty reply` / `(56) reset`** — порт проброшен, но в контейнере приложение слушает другой порт или только `127.0.0.1` контейнера: приложение должно слушать `0.0.0.0`.

### quiz
- Что делает Docker, когда ты указываешь `-p 8080:80`?
- Чем `-p 127.0.0.1:3022:3000` отличается от `-p 3022:3000`?
- Почему `EXPOSE 3000` без `-p` не открывает порт?

### links
- https://docs.docker.com/engine/network/port-publishing/ | публикация портов | Port publishing and mapping
- https://docs.docker.com/reference/dockerfile/#expose | EXPOSE | Dockerfile EXPOSE

## 6.3 Свои сети и DNS по имени | short: Своя сеть и DNS | est: ~35 мин
### intro
**Слова шага:** *пользовательская сеть*, *`docker network create`*, *встроенный DNS*, *имя контейнера*, *`--network`*.

:::tip Если совсем просто
В сети по умолчанию есть только номера телефонов. В **своей** сети Docker заводит ещё и **телефонную книгу**: достаточно сказать «позвони api» — и Docker сам найдёт номер. Поэтому контейнеры из твоего проекта всегда создают в **своей** сети.
:::

Первое правило сетей Docker: **для каждого проекта делай свою сеть.** В пользовательской (user-defined) сети bridge работает **встроенный DNS-сервер Docker**: он знает имена всех контейнеров сети и отвечает адресом контейнера. Создадим сеть, запустим API с именем `api` и обратимся к нему по имени из другого контейнера:

```bash run
docker network create coffee-net
docker run -d --name api --network coffee-net coffee-api:slim
sleep 2
docker run --rm --network coffee-net alpine:3.22 sh -c 'wget -qO- http://api:3000/health; echo'
docker run --rm --network coffee-net alpine:3.22 nslookup api
```

### result
```out auto
```

`wget` получил ответ `{"status":"ok"}` по адресу `http://api:3000` — **без IP и без публикации порта**: оба контейнера в одной сети, и имя `api` разрешил встроенный DNS (`127.0.0.11` — адрес этого DNS внутри контейнера; в выводе `nslookup` он указан как `Server`). Теперь тот же вызов из сети по умолчанию — для сравнения:

```bash run
docker run --rm alpine:3.22 wget -qO- -T 2 http://api:3000/health
```

```out auto
```

`bad address 'api'` — контейнер не в той сети, поэтому имя не найдено, хотя сам `api` работает. **Имена видны только внутри общей пользовательской сети.** Сравни сети и их участников:

```bash run
docker network ls --filter name=coffee
docker network inspect coffee-net --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'
```

```out auto
```

Теперь на практике понятно, как в Compose (сессия 8) один сервис находит другой по имени: Compose создаёт для проекта свою сеть, а имена сервисов становятся DNS-именами. Для чистоты уберём:

```bash run
docker rm -f api
docker network rm coffee-net
```

```out auto
```

### why
Два вывода: **1)** «подключаться по IP» — плохой подход, адреса меняются при каждом пересоздании контейнера; **2)** имя контейнера в своей сети — стабильный адрес. Поэтому в конфигурации приложения пишут `DB_HOST=db`, а не IP-адрес, и поэтому свой `api` из шага 6.1 не находился по имени, а в `coffee-net` находится.

### deep Команда по частям
`docker run --rm --network coffee-net alpine:3.22 wget -qO- http://api:3000/health`: `--network coffee-net` — подключить контейнер к этой сети; `wget -qO- URL` — скачать страницу тихо (`-q`) и вывести в терминал (`-O-`); `api` — имя контейнера, разрешаемое DNS. `docker network create coffee-net` — создаёт сеть с драйвером `bridge` по умолчанию.

### deep Как ещё можно
- **Задать подсеть:** `docker network create --subnet 10.10.0.0/24 coffee-net`.
- **Алиас в сети:** `docker run --network-alias backend …` — контейнер доступен ещё и под этим именем (шаг 6.5).
- **Чужие имена и «сосед»:** `--link` — устаревший способ, не используй.

### deep Если не получилось
- **`bad address 'api'`** — контейнеры в разных сетях; проверь `docker inspect --format '{{json .NetworkSettings.Networks}}' имя`.
- **Имя не находится сразу после запуска** — контейнер ещё не создан; подожди секунду.
- **`network coffee-net has active endpoints`** (при удалении) — в сети ещё есть контейнеры; сначала удали их.

### quiz
- Чем пользовательская сеть отличается от сети `bridge` по умолчанию?
- Почему в настройках приложения пишут имя контейнера, а не его IP?
- Какой адрес у встроенного DNS Docker внутри контейнера?

### links
- https://docs.docker.com/engine/network/drivers/bridge/#differences-between-user-defined-bridges-and-the-default-bridge | пользовательская и стандартная bridge | User-defined vs default bridge

## 6.4 Другие драйверы: host, none, overlay, macvlan | short: Драйверы сети | est: ~25 мин
### intro
**Слова шага:** *сетевой драйвер*, *`host`*, *`none`*, *`overlay`*, *`macvlan`*.

:::tip Если совсем просто
Драйвер — это «тип проводки» в комнатах. Bridge — комнаты в одном доме с внутренним телефоном. `none` — комната без телефона вообще. `host` — вообще без стен: контейнер сидит в общей комнате с хозяином и слушает его телефон. `overlay` — телефонная связь **между разными домами** (серверами).
:::

Драйвер определяет, как устроена сеть. Основные:

| Драйвер | Что делает | Когда нужен |
|---|---|---|
| `bridge` | виртуальный коммутатор на одном хосте (по умолчанию) | почти всегда |
| `host` | контейнер использует сеть хоста напрямую, без изоляции | максимум скорости, нет проброса портов |
| `none` | у контейнера только `lo` (петля), сети нет | изоляция: обработка без сети |
| `overlay` | сеть поверх нескольких хостов (Swarm, Kubernetes) | кластеры |
| `macvlan` | контейнер получает «настоящий» адрес в сети хоста | устаревшие системы, мониторинг |

Проверим `none` и `host` на практике. Команда `ip -o addr` показывает адреса интерфейсов:

```bash run
echo "--- none: только петля"
docker run --rm --network none alpine:3.22 ip -o addr
echo "--- host: сетевые интерфейсы хоста (у тебя на Mac — интерфейсы VM Docker)"
docker run --rm --network host alpine:3.22 ip -o addr | head -4
```

### result
```out auto
```

У `none` — единственный интерфейс `lo` (`127.0.0.1`): контейнер полностью отрезан от сети. У `host` виден список интерфейсов **самого хоста** (его `eth0`, `docker0` и т. д.) — контейнер не получил своего стека и использует хостовый. При `host` публиковать порты (`-p`) не нужно и не получится: порты приложения сразу становятся портами хоста.

:::trap Ограничение на Mac
На Mac «хост» в `--network host` — это **виртуальная машина Docker Desktop**, а не твой Mac. Приложение, запущенное с `--network host`, обычно **недоступно** с `localhost` твоего Mac (в новых версиях Docker Desktop есть опциональная поддержка host-сети в настройках). Поэтому на Mac для публикации всегда используй `-p`, а `host` оставь для Linux-серверов.
:::

`overlay` и `macvlan` мы только упомянули: `overlay` нужен для кластеров (Swarm и Kubernetes — вне этой лабы), а `macvlan` — редкий случай, когда контейнеру нужен собственный адрес в локальной сети; на Mac он не работает. В повседневной жизни ты пользуешься `bridge` (своими сетями).

### why
Драйвер редко приходится менять, но знать выбор полезно: когда-то ты услышишь «поставь `network_mode: host`» (обычно ради производительности) или «overlay-сеть» (в кластере) и поймёшь, о чём речь. А пока правило такое: **свои bridge-сети для проектов, `-p` для публикации, `host` — осознанно и только на Linux.**

### deep Как ещё можно
- **Создать сеть с драйвером:** `docker network create -d bridge имя` (`-d` — driver); для `overlay` нужен режим кластера.
- **`--network container:имя`** — подключить контейнер к сетевому стеку другого контейнера (используется для отладки и «sidecar»-контейнеров).
- **Узнать драйвер сети:** `docker network inspect имя --format '{{.Driver}}'`.

### deep Если не получилось
- **`--network host` и порты не работают на Mac** — это ограничение VM (см. выше).
- **Приложение в `host` занимает порт, который уже занят** — конфликт с процессами хоста; в `host` нет изоляции портов.

### quiz
- Чем драйвер `none` отличается от `bridge`? Что в нём остаётся?
- Почему `--network host` на Mac работает не так, как на Linux?
- Для чего нужен `overlay` и почему он не нужен в нашей лабе?

### links
- https://docs.docker.com/engine/network/drivers/ | сетевые драйверы | Network drivers
- https://docs.docker.com/engine/network/drivers/host/ | драйвер host | Host network driver

## 6.5 Несколько сетей, connect, alias | short: Несколько сетей | est: ~30 мин
### intro
**Слова шага:** *`network connect`*, *`network disconnect`*, *алиас (`--network-alias`)*, *изоляция сетей*.

:::tip Если совсем просто
Два отдела компании сидят в разных коридорах. Бухгалтерия (база данных) видна только тем, кто в её коридоре. Чтобы **сотрудник из приёмной** мог пообщаться с бухгалтерией, ему не дают ключи от всего — а вводят **посредника**, который ходит в оба коридора (это наш API).
:::

Контейнер может быть подключён **к нескольким сетям** сразу и видит в каждой своих соседей. Так делают, чтобы **ограничить связи**: сайт не должен «видеть» базу напрямую, ему достаточно API. Попробуем на простых контейнерах. Создадим две сети и три контейнера: `app-a` — только в первой, `app-c` — только во второй, `app-b` — в обеих:

```bash run
docker network create net-one
docker network create net-two
docker run -d --name app-a --network net-one alpine:3.22 sleep 300
docker run -d --name app-b --network net-one alpine:3.22 sleep 300
docker run -d --name app-c --network net-two alpine:3.22 sleep 300
docker network connect net-two app-b
docker exec app-a ping -c 1 app-b
docker exec app-a ping -c 1 app-c
docker exec app-b ping -c 1 app-c
```

### result
```out auto
```

Читай по строкам: `app-a → app-b` работает (общая `net-one`); `app-a → app-c` — `bad address 'app-c'` (общих сетей нет, имени не существует); `app-b → app-c` работает (`app-b` подключён ещё и к `net-two` командой `docker network connect`). Контейнер `app-b` — тот самый «посредник». Посмотрим, в каких сетях `app-b`:

```bash run
docker inspect --format '{{range $name, $net := .NetworkSettings.Networks}}{{$name}}: {{$net.IPAddress}}{{"\n"}}{{end}}' app-b
```

```out auto
```

Два адреса, по одному в каждой сети. Отключить сеть можно так же просто, и общение сразу прекратится:

```bash run
docker network disconnect net-two app-b
docker exec app-b ping -c 1 app-c
```

```out auto
```

**Алиасы.** Контейнеру можно дать в сети дополнительное имя (`--network-alias`), хотя настоящее имя другое. Удобно, когда несколько контейнеров должны отвечать на одно имя, или имя «роль» отличается от имени «контейнера»:

```bash run
docker run -d --name cache-1 --network net-one --network-alias cache alpine:3.22 sleep 300
docker exec app-a ping -c 1 cache
docker rm -f app-a app-b app-c cache-1
docker network rm net-one net-two
```

```out auto
```

### why
Изоляция сетей — это дешёвый, но мощный способ безопасности: компрометация сайта не даёт прямого доступа к базе, потому что сайт не в той сети. Сделай привычкой «минимум связей»: каждая пара сервисов, которым нужно общаться, получает общую сеть, остальные — нет.

### deep Команда по частям
`docker network connect net-two app-b`: подключить уже работающий контейнер `b` к сети `net-two` (не перезапуская). `docker run … --network-alias cache`: в сети контейнер доступен как под своим именем (`cache-1`), так и под именем `cache`. В Compose всё это записывается секцией `networks` (сессия 8).

### deep Если не получилось
- **`network net-two not found`** — сеть не создана: сначала `docker network create`.
- **`endpoint with name app-b already exists in network net-two`** — контейнер уже подключён; смотри `docker inspect`.
- **`ping: bad address` внутри «общей» сети** — проверь, что оба контейнера точно подключены к ней (`docker network inspect имя`).

### quiz
- Как сделать так, чтобы контейнеры A и C не видели друг друга, а B видел обоих?
- Что делает `docker network connect`?
- Для чего нужен `--network-alias`?

### links
- https://docs.docker.com/reference/cli/docker/network/connect/ | docker network connect | docker network connect

## 6.6 Собираем сеть CoffeeShop и учимся её диагностировать | short: Сеть CoffeeShop | est: ~50 мин
### intro
**Слова шага:** *топология*, *`proxy_pass`*, *`resolver`*, *`nslookup`*, *`network inspect`*, *netshoot*.

:::tip Если совсем просто
Теперь строим настоящий «город»: на улице стоит **вывеска** (`web` — nginx), за ней **администратор** (`api`), а в сейфовой комнате — **бухгалтерия** (`db`). Гости ходят только к вывеске, вывеска зовёт администратора, администратор — бухгалтерию. Дверь в сейфовую комнату на улицу **не выходит**.
:::

Соберём стек CoffeeShop по этой схеме. Две сети: `coffee-front` (сайт ↔ API) и `coffee-back` (API ↔ база). API подключён к обеим; у базы **нет опубликованных портов**.

```svg
<svg viewBox="0 0 640 260" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Топология CoffeeShop: две сети, БД закрыта от внешнего мира" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m2-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m2-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><rect x="10" y="105" width="100" height="50" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="60.0" y="126.0" text-anchor="middle" font-size="12" fill="currentColor">Браузер</text><text x="60.0" y="144.0" text-anchor="middle" font-size="12" fill="currentColor">localhost:8080</text><line x1="110" y1="130" x2="150" y2="130" stroke="currentColor" stroke-width="1.8" marker-end="url(#m2-e)"/><text x="130.0" y="123.0" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">-p</text><rect x="150" y="20" width="220" height="220" rx="8" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="260" y="14" text-anchor="middle" font-size="12" font-weight="700" fill="currentColor" fill-opacity="1">сеть coffee-front</text><rect x="165" y="100" width="80" height="60" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="205.0" y="126.0" text-anchor="middle" font-size="13" fill="currentColor">web</text><text x="205.0" y="144.0" text-anchor="middle" font-size="13" fill="currentColor">nginx</text><rect x="272" y="100" width="80" height="60" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="312.0" y="126.0" text-anchor="middle" font-size="13" fill="currentColor">api</text><text x="312.0" y="144.0" text-anchor="middle" font-size="13" fill="currentColor">Node</text><line x1="245" y1="130" x2="272" y2="130" stroke="currentColor" stroke-width="1.8" marker-end="url(#m2-e)" marker-start="url(#m2-s)"/><rect x="280" y="20" width="350" height="220" rx="8" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="455" y="14" text-anchor="middle" font-size="12" font-weight="700" fill="currentColor" fill-opacity="1">сеть coffee-back</text><rect x="272" y="100" width="80" height="60" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="312.0" y="126.0" text-anchor="middle" font-size="13" fill="currentColor">api</text><text x="312.0" y="144.0" text-anchor="middle" font-size="13" fill="currentColor">Node</text><rect x="500" y="100" width="110" height="60" rx="8" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.5"/><text x="555.0" y="126.0" text-anchor="middle" font-size="13" fill="currentColor">db</text><text x="555.0" y="144.0" text-anchor="middle" font-size="13" fill="currentColor">PostgreSQL</text><line x1="352" y1="130" x2="500" y2="130" stroke="currentColor" stroke-width="1.8" marker-end="url(#m2-e)" marker-start="url(#m2-s)"/><text x="430" y="122" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">:5432</text><text x="515" y="205" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.9">у db нет -p: снаружи недоступна</text><text x="200" y="205" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.9">web не видит db</text></svg>
```

Сначала научим сайт ходить к API. В `nginx` для этого добавляем конфиг: запросы на `/api/…` перенаправляются (`proxy_pass`) на контейнер `api`. `resolver 127.0.0.11` — адрес встроенного DNS Docker (шаг 6.3): благодаря нему nginx **находит `api` по имени в момент запроса**, а не при старте (иначе nginx упадёт, если API ещё не запущен). Добавим файл и пересоберём образ сайта:

```bash run
cd ~/docker-lab/coffeeshop/web
cat > nginx.conf <<'EOF'
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri /index.html;
    }

    location /api/ {
        resolver 127.0.0.11 valid=10s;
        set $api_upstream http://api:3000;
        rewrite ^/api/(.*)$ /$1 break;
        proxy_pass $api_upstream;
    }
}
EOF
cat > Dockerfile <<'EOF'
FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY src ./src
RUN npm run build

FROM nginx:1.30-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY --from=build /app/dist/app.js /usr/share/nginx/html/app.js
EXPOSE 80
EOF
docker build -q -t coffee-web:2 .
```

### result
```out auto
```

Поднимаем стек. Базе даём пароль (шаг 2.7) и пока без тома — данные мы научимся хранить в сессии 7. API подключаем сразу к бэк-сети, а потом добавляем во фронт-сеть командой `docker network connect` (шаг 6.5):

```bash run
docker network create coffee-front
docker network create coffee-back
docker run -d --name db --network coffee-back -e POSTGRES_PASSWORD=secret postgres:18
docker run -d --name api --network coffee-back coffee-api:slim
docker network connect coffee-front api
docker run -d --name web --network coffee-front -p 8080:80 coffee-web:2
sleep 5
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

```out auto
```

В колонке `PORTS` порт есть **только у `web`**: `db` и `api` снаружи недоступны. Проверим цепочку «браузер → web → api»:

```bash run
curl -s -w '\n' http://localhost:8080/api/health
curl -s -w '\n' http://localhost:8080/api/menu
curl -s http://localhost:8080/ | grep '<h1>'
```

```out auto
```

Сайт отдаёт страницу, а запросы `/api/…` nginx пересылает на API и возвращает ответ. Теперь убедимся, что «связи именно такие, как надо». Инструменты для диагностики берём в одноразовом контейнере — в Alpine ставим `bind-tools` (даёт `nslookup`) и `curl` на лету (`apk add` — менеджер пакетов Alpine). Готовый «швейцарский нож» для этого — образ `nicolaka/netshoot` (около 1 ГБ, поэтому в лабе его не запускаем):

```bash run
echo "--- из front: api виден по имени"
docker run --rm --network coffee-front alpine:3.22 sh -c 'apk add -q --no-cache bind-tools curl && nslookup api | tail -2 && curl -s -w "\n" http://api:3000/health'
echo "--- из front: db не виден"
docker run --rm --network coffee-front alpine:3.22 sh -c 'apk add -q --no-cache bind-tools && nslookup db | tail -2'
echo "--- из back: db отвечает"
docker run --rm --network coffee-back postgres:18 pg_isready -h db -U postgres
```

```out auto
```

Картина совпадает со схемой: из сети `coffee-front` имя `api` разрешается, а `db` — нет (`Can't find db`: такого имени в этой сети не существует); из `coffee-back` база готова принимать подключения (`accepting connections`). Диагностика сети всегда идёт одними и теми же шагами: **кто с кем в одной сети** (`docker network inspect`), **находится ли имя** (`nslookup`), **отвечает ли порт** (`curl`/`pg_isready`/`nc -zv`), **слушает ли приложение нужный порт на `0.0.0.0`** (`docker exec … ss -tln`, если есть оболочка):

```bash run
docker network inspect coffee-front --format 'front: {{range .Containers}}{{.Name}} {{end}}'
docker network inspect coffee-back --format 'back: {{range .Containers}}{{.Name}} {{end}}'
```

```out auto
```

### why
Это первая версия «настоящей» архитектуры CoffeeShop: публичная часть (сайт) отделена от приватной (база), и между ними — посредник. Дальше (сессия 8) то же самое запишется одним файлом `compose.yaml`, а пока ты понимаешь, что за каждой его строкой стоит команда, которую ты уже запускала руками.

### deep Команда по частям
`rewrite ^/api/(.*)$ /$1 break;` — отрезать префикс `/api/`, чтобы API получил обычный путь (`/menu`), а не `/api/menu`; `break` — продолжить обработку уже с новым путём. `set $api_upstream http://api:3000;` + `proxy_pass $api_upstream;` — адрес в переменной заставляет nginx разрешать имя в момент запроса через `resolver`. `valid=10s` — как долго nginx помнит ответ DNS.

### deep Если не получилось
- **`502 Bad Gateway` на `/api/...`** — nginx не достучался до `api`: контейнеры в разных сетях, имя `api` не совпадает или API не запущен (`docker logs web`, `docker ps`).
- **`host not found in upstream "api"` при старте web** — в конфиге `proxy_pass http://api:3000` написан без переменной и `resolver`; nginx проверяет имя при старте.
- **`pg_isready … no response`** — база ещё запускается (подожди 5–10 секунд).

### quiz
- Почему у `db` нет опубликованного порта и кто может к ней подключиться?
- Для чего в конфиге nginx нужен `resolver 127.0.0.11`?
- Какие четыре вопроса задаёшь по порядку, когда «сервис A не достучался до B»?

### links
- https://nginx.org/en/docs/http/ngx_http_proxy_module.html | модуль proxy в nginx | ngx_http_proxy_module
- https://github.com/nicolaka/netshoot | netshoot — набор сетевых инструментов | netshoot

## 6.7 🔨 Сломать → починить: «контейнер A не видит B» | short: A не видит B | est: ~30 мин
### intro
**Слова шага:** *разные сети*, *сеть по умолчанию*, *порядок запуска*, *диагностика сверху вниз*.

:::tip Если совсем просто
«Я звоню коллеге, а он не берёт трубку». Прежде чем ругать телефон, проверь: **вы вообще в одном здании?** (одна сеть) **Он на месте?** (контейнер запущен) **Слушает ли именно этот номер?** (порт приложения). Так и ищем.
:::

Сломаем сеть двумя типичными способами и починим. Стек из шага 6.6 ещё работает.

**Поломка 1: контейнеры в разных сетях.** Добавим в бэк-сеть кеш (`cache`) и попробуем достучаться до него с сайта:

```bash run
docker run -d --name cache --network coffee-back alpine:3.22 sleep 300
docker exec web ping -c 1 -W 2 cache
```

### result
```out auto
```

`bad address 'cache'` — имени в сети `coffee-front` нет. Диагностика по шагам: **1)** контейнер `cache` запущен? (`docker ps`) — да; **2)** в какой сети? — `docker inspect --format '{{json .NetworkSettings.Networks}}' cache` покажет только `coffee-back`; **3)** `web` в `coffee-front` — общей сети нет. Правильное решение зависит от архитектуры: если сайту действительно нужен кеш, подключи кеш и к фронт-сети; но здесь кеш нужен только API, поэтому **сайту доступ не нужен — это не поломка, а изоляция работает**. Проверим то, что должно работать: API (он в обеих сетях) кеш видит:

```bash run
docker run --rm --network coffee-back alpine:3.22 ping -c 1 cache
```

```out auto
```

**Поломка 2: сервис в сети по умолчанию.** Самая частая ошибка: контейнер запущен **без `--network`**, поэтому оказался в сети `bridge` и не видит остальных по имени:

```bash run
docker run -d --name stray alpine:3.22 sleep 300
docker exec stray wget -qO- -T 2 http://api:3000/health 2>&1 | tail -1
docker network connect coffee-front stray
docker exec stray wget -qO- -T 2 http://api:3000/health
```

```out auto
```

Первый вызов — `bad address 'api'`: контейнер `stray` в сети по умолчанию, DNS по именам там нет. После `docker network connect coffee-front stray` тот же вызов работает: `stray` теперь в одной сети с `api`. Постоянное решение — создавать контейнер сразу с `--network coffee-front`.

Алгоритм для любого «A не видит B» — сверху вниз:

1. **Запущен ли B?** `docker ps`, `docker logs B`.
2. **Одна ли сеть?** `docker network inspect <сеть>` — оба в списке?
3. **Разрешается ли имя?** `nslookup B` из контейнера A.
4. **Слушает ли B нужный порт на `0.0.0.0`?** Приложение должно слушать не `127.0.0.1`.
5. **Не мешает ли что-то посередине?** Лишь потом смотри файрвол и прокси.

Убираем весь стек:

```bash run
docker rm -f web api db cache stray
docker network rm coffee-front coffee-back
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
docker network ls --format '{{.Name}}'
```

```out auto
```

### why
Эти два сценария — 90% сетевых проблем в Docker: «не в той сети» и «приложение слушает не тот адрес». Проверка по порядку сверху вниз не даёт гадать: ты находишь, на каком шаге цепочка рвётся, и чинишь именно его.

### deep Если не получилось
- **Связь есть, но «Connection refused»** — имя найдено, сеть общая, а порт закрыт: приложение не запущено, слушает другой порт или `127.0.0.1` (в Node: `app.listen(3000, '0.0.0.0')`; Express по умолчанию слушает все адреса).
- **Имя не находится сразу после `docker run`** — подожди секунду, DNS обновляется после старта.
- **Контейнер не удаляется (`network has active endpoints`)** — отключи или удали контейнеры сети.

### quiz
- Назови первые три вопроса, которые задаёшь, когда контейнер A «не видит» B.
- Почему контейнер, запущенный без `--network`, не находит других по имени?
- Как исправить это на лету и как сделать правильно навсегда?

### outro
:::tip Приёмка сессии 6
- Ты объясняешь, что у контейнера свой сетевой стек и свой `localhost`, и показываешь IP контейнера.
- Ты различаешь `-p 8080:80`, `-p 127.0.0.1:…` и `-P`, знаешь, что `EXPOSE` порт не открывает.
- Ты создаёшь пользовательскую сеть и показываешь, что контейнеры находят друг друга по имени (а в сети по умолчанию — нет).
- Стек CoffeeShop (`web` → `api` → `db`) собран на двух сетях: у `db` нет опубликованного порта, `web` не видит `db`, `/api/menu` через сайт отвечает.
- Ты диагностируешь «A не видит B» по пяти шагам сверху вниз.
:::
