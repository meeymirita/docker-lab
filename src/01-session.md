# Сессия 1 · Азбука контейнеров и установка
dur: ~3,5 ч

## 1.1 Проблема «у меня работает» | short: Зачем нужен Docker | est: ~20 мин
### intro
**Слова шага:** *зависимость*, *окружение*, *виртуальная машина*, *контейнер*, *образ*.

:::tip Если совсем просто
Представь, что печёшь торт по рецепту. У тебя дома получается вкусно, а у подруги — другая плита, другая мука, и выходит комом. Docker кладёт в одну коробку **и рецепт, и муку, и плиту**: открыл коробку где угодно — получил тот же торт.
:::

```svg
<svg viewBox="0 0 640 250" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Сравнение: виртуальные машины и контейнеры" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m1-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m1-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><text x="160" y="22" text-anchor="middle" font-size="14" font-weight="700" fill="currentColor" fill-opacity="1">Виртуальные машины: три дома</text><rect x="15" y="40" width="90" height="34" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="60.0" y="62.0" text-anchor="middle" font-size="12" fill="currentColor">Приложение</text><rect x="15" y="78" width="90" height="62" rx="8" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.5"/><text x="60.0" y="105.0" text-anchor="middle" font-size="12" fill="currentColor">Своя ОС</text><text x="60.0" y="123.0" text-anchor="middle" font-size="12" fill="currentColor">и своё ядро</text><rect x="112" y="40" width="90" height="34" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="157.0" y="62.0" text-anchor="middle" font-size="12" fill="currentColor">Приложение</text><rect x="112" y="78" width="90" height="62" rx="8" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.5"/><text x="157.0" y="105.0" text-anchor="middle" font-size="12" fill="currentColor">Своя ОС</text><text x="157.0" y="123.0" text-anchor="middle" font-size="12" fill="currentColor">и своё ядро</text><rect x="209" y="40" width="90" height="34" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="254.0" y="62.0" text-anchor="middle" font-size="12" fill="currentColor">Приложение</text><rect x="209" y="78" width="90" height="62" rx="8" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.5"/><text x="254.0" y="105.0" text-anchor="middle" font-size="12" fill="currentColor">Своя ОС</text><text x="254.0" y="123.0" text-anchor="middle" font-size="12" fill="currentColor">и своё ядро</text><rect x="15" y="146" width="284" height="30" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="157.0" y="166.0" text-anchor="middle" font-size="13" fill="currentColor">Гипервизор</text><rect x="15" y="180" width="284" height="30" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="157.0" y="200.0" text-anchor="middle" font-size="12" fill="currentColor">Железо (процессор, память, диск)</text><text x="480" y="22" text-anchor="middle" font-size="14" font-weight="700" fill="currentColor" fill-opacity="1">Контейнеры: три квартиры</text><rect x="336" y="40" width="90" height="34" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="381.0" y="62.0" text-anchor="middle" font-size="12" fill="currentColor">Приложение</text><rect x="336" y="78" width="90" height="28" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="381.0" y="97.0" text-anchor="middle" font-size="12" fill="currentColor">Свои файлы</text><rect x="433" y="40" width="90" height="34" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="478.0" y="62.0" text-anchor="middle" font-size="12" fill="currentColor">Приложение</text><rect x="433" y="78" width="90" height="28" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="478.0" y="97.0" text-anchor="middle" font-size="12" fill="currentColor">Свои файлы</text><rect x="530" y="40" width="90" height="34" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="575.0" y="62.0" text-anchor="middle" font-size="12" fill="currentColor">Приложение</text><rect x="530" y="78" width="90" height="28" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="575.0" y="97.0" text-anchor="middle" font-size="12" fill="currentColor">Свои файлы</text><rect x="336" y="112" width="284" height="30" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="478.0" y="132.0" text-anchor="middle" font-size="13" fill="currentColor">Docker</text><rect x="336" y="146" width="284" height="30" rx="8" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.5"/><text x="478.0" y="166.0" text-anchor="middle" font-size="13" fill="currentColor">Одна ОС, общее ядро</text><rect x="336" y="180" width="284" height="30" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="478.0" y="200.0" text-anchor="middle" font-size="12" fill="currentColor">Железо (процессор, память, диск)</text><text x="160" y="235" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">тяжело: у каждого своя система</text><text x="480" y="235" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">легко: система одна на всех</text></svg>
```

Знакомая сцена: ты написала приложение, оно работает на твоём Mac, ты отправляешь его на сервер — и оно падает. Там другая версия Node, нет нужной библиотеки, другой путь к файлу, другая настройка системы. Приложение — это не только твой код, а ещё **окружение**: версия языка, системные библиотеки, переменные, права. Код один, окружения разные, поэтому «у меня работает» и «у тебя не работает» бывают одновременно.

Есть два способа выровнять окружения.

**Виртуальная машина (VM)** — целый компьютер внутри компьютера: своё «железо» на бумаге, своя операционная система с ядром, свои программы. Надёжно, но тяжело: гигабайты диска, минуты на запуск, и вся система занимает память, даже когда приложение маленькое.

**Контейнер** — не отдельный компьютер, а *изолированный процесс*: он запущен на ядре самой системы, но видит только свои файлы, свои процессы и свою сеть. Ядра в нём нет, поэтому он весит мегабайты и стартует за долю секунды.

:::tip Аналогия
VM — отдельный дом: свой фундамент, свои стены, свои коммуникации. Контейнер — квартира в одном доме: фундамент и трубы общие (ядро), а двери заперты, и у каждого жильца свой ключ и своё хозяйство. Домов можно построить десять, но каждый тяжёлый; квартир можно сделать сотню, и они лёгкие.
:::

**Образ** — «слепок» окружения: приложение вместе со всем, что ему нужно, в виде неизменяемого набора файлов. **Контейнер** — запущенный по образу процесс. Один образ, много контейнеров — как один чертёж и много построенных по нему квартир. Образ можно отправить на любой компьютер с Docker, и приложение запустится там так же, как у тебя. Это и есть решение проблемы «у меня работает».

### why
Docker решает именно организационную проблему: он не делает приложение быстрее или умнее, а делает окружение **описанным в файле и воспроизводимым**. Дальше во всей лабе ты будешь описывать окружения текстом (`Dockerfile`, `compose.yaml`), а не настраивать их руками на живой машине. Поэтому первая идея — «окружение — это тоже код».

### deep Контейнер и VM в цифрах
Для небольшого Node-приложения образ с Alpine занимает порядка 150–200 МБ, запускается за доли секунды и использует память только на процесс приложения. Полноценная VM с Linux и теми же программами — несколько гигабайт диска, 10–30 секунд на загрузку и сотни мегабайт памяти на саму систему. Другое отличие — переносимость: образ собран один раз, а запускается и на твоём ноутбуке, и на сервере.

### deep Контейнер — это не «лёгкая VM»
Частая ошибка новичка — думать про контейнер как про маленький компьютер, в который заходят по SSH и ставят всё руками. Контейнер задуман как **один процесс одного приложения** — запустил, он отработал, остановил, удалил. Всё, что должно жить дольше (данные базы), хранится снаружи, в томах (сессия 7). Если ты ловишь себя на мысли «зайду в контейнер и поправлю» — это почти всегда сигнал поправить `Dockerfile`.

### quiz
- Почему приложение может работать на твоём Mac и падать на сервере, если код один и тот же?
- Чем контейнер отличается от виртуальной машины по тому, что у него есть (а чего нет)?
- Чем образ отличается от контейнера? (Подсказка: чертёж и квартира.)

### links
- https://docs.docker.com/get-started/docker-overview/ | что такое Docker | Docker overview

## 1.2 Как устроен Docker: клиент, демон, ядро | short: Устройство Docker | est: ~35 мин
### intro
**Слова шага:** *клиент (`docker`)*, *демон (`dockerd`)*, *`containerd`*, *`runc`*, *namespace*, *cgroup*, *registry*.

:::tip Если совсем просто
Docker работает как кафе. Ты говоришь официанту: «Хочу капучино». Официант (`docker`) несёт заказ менеджеру (`dockerd`), менеджер — повару (`containerd`), повар включает кофемашину (`runc`). С кофемашиной ты не разговариваешь — только с официантом. А чтобы жильцам не мешать друг другу, ядро даёт каждому «шоры» (что видно) и «счётчик» (сколько можно взять).
:::

```svg
<svg viewBox="0 0 640 240" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Путь команды docker run до процесса" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m2-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m2-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><rect x="8" y="20" width="106" height="54" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="61.0" y="43.0" text-anchor="middle" font-size="13" fill="currentColor">Ты</text><text x="61.0" y="61.0" text-anchor="middle" font-size="13" fill="currentColor">docker run …</text><line x1="114" y1="47" x2="132" y2="47" stroke="currentColor" stroke-width="1.8" marker-end="url(#m2-e)"/><rect x="132" y="20" width="106" height="54" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="185.0" y="43.0" text-anchor="middle" font-size="13" fill="currentColor">docker</text><text x="185.0" y="61.0" text-anchor="middle" font-size="13" fill="currentColor">клиент</text><line x1="238" y1="47" x2="256" y2="47" stroke="currentColor" stroke-width="1.8" marker-end="url(#m2-e)"/><rect x="256" y="20" width="106" height="54" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="309.0" y="43.0" text-anchor="middle" font-size="13" fill="currentColor">dockerd</text><text x="309.0" y="61.0" text-anchor="middle" font-size="13" fill="currentColor">демон</text><line x1="362" y1="47" x2="380" y2="47" stroke="currentColor" stroke-width="1.8" marker-end="url(#m2-e)"/><rect x="380" y="20" width="106" height="54" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="433.0" y="43.0" text-anchor="middle" font-size="13" fill="currentColor">containerd</text><text x="433.0" y="61.0" text-anchor="middle" font-size="13" fill="currentColor">менеджер</text><line x1="486" y1="47" x2="504" y2="47" stroke="currentColor" stroke-width="1.8" marker-end="url(#m2-e)"/><rect x="504" y="20" width="106" height="54" rx="8" fill="currentColor" fill-opacity="0.1" stroke="currentColor" stroke-width="1.5"/><text x="557.0" y="43.0" text-anchor="middle" font-size="13" fill="currentColor">runc</text><text x="557.0" y="61.0" text-anchor="middle" font-size="13" fill="currentColor">создаёт</text><rect x="220" y="100" width="200" height="38" rx="8" fill="currentColor" fill-opacity="0.16" stroke="currentColor" stroke-width="1.5"/><text x="320.0" y="124.0" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor">Твой процесс в контейнере</text><line x1="570" y1="74" x2="420" y2="112" stroke="currentColor" stroke-width="1.8" marker-end="url(#m2-e)"/><text x="320" y="228" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">как в кафе: ты → официант → менеджер → повар → кофемашина</text><rect x="8" y="155" width="300" height="52" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="158.0" y="177.0" text-anchor="middle" font-size="12" fill="currentColor">namespace — шоры:</text><text x="158.0" y="195.0" text-anchor="middle" font-size="12" fill="currentColor">процесс видит только своё</text><rect x="332" y="155" width="300" height="52" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="482.0" y="177.0" text-anchor="middle" font-size="12" fill="currentColor">cgroup — счётчик:</text><text x="482.0" y="195.0" text-anchor="middle" font-size="12" fill="currentColor">сколько памяти и процессора можно</text></svg>
```

Когда ты вводишь `docker run …`, программа `docker` сама ничего не запускает. Это **клиент**: он превращает твою команду в запрос и отправляет его **демону**.

**Демон `dockerd`** — фоновая программа, которая и управляет образами, сетями, томами и контейнерами. Демон передаёт запуск контейнера низкоуровневому менеджеру **`containerd`**, а тот вызывает **`runc`** — крошечную программу, которая настоящим образом создаёт изолированный процесс и выходит из игры. Цепочка выглядит так:


Образы демон берёт из **registry** — хранилища образов. Главное публичное хранилище — Docker Hub (`hub.docker.com`): оттуда придёт `hello-world` в шаге 1.4.

Теперь главный вопрос: как `runc` «запирает» процесс? Он использует две возможности самого ядра Linux (Docker их не изобретал):

- **Namespaces (пространства имён)** отвечают на вопрос «что процесс *видит*»: свои процессы, свою сеть, своё имя хоста, свою файловую систему. Для процесса внутри контейнера `ps` показывает только его собственные процессы.
- **Cgroups (контрольные группы)** отвечают на вопрос «сколько процесс *может использовать*»: потолок памяти, процессора, числа процессов.

Проверим оба на практике. Образ `alpine` — крошечный Linux (около 8 МБ); `--rm` значит «удали контейнер после выхода». Сначала namespace процессов:

```bash run
docker run --rm alpine ps
```

### result
Ответ короткий: контейнер видит только свой процесс, а не все процессы машины.

```out auto
```

Это namespace процессов: у процесса номер (PID) **1**, как будто он единственный в мире. Теперь cgroup — ограничим память контейнера 64 мегабайтами и спросим у самого контейнера, какой у него потолок:

```bash run
docker run --rm -m 64m alpine cat /sys/fs/cgroup/memory.max
```

```out auto
```

`67108864` — это 64 × 1024 × 1024 байт. Ядро будет принудительно держать процесс в этих рамках. И последняя проверка: чьё ядро у контейнера? Спросим версию ядра внутри контейнера:

```bash run
docker run --rm alpine uname -sr
```

```out auto
```

В ответе `Linux` и версия ядра с припиской `linuxkit` — так называется минимальная Linux-система внутри Docker Desktop. На своём Mac та же команда даёт другой результат:

```bash
uname -sr
```

```out
Darwin 25.6.0
```

**Darwin** — ядро macOS, а контейнеру нужен Linux. Docker Desktop решает это просто: запускает у себя одну лёгкую Linux-VM, и все контейнеры работают на её ядре (подробности — в шаге 1.3).

### why
Три слова запоминаются навсегда: **namespace — что видит, cgroup — сколько может, ядро — общее**. Из этого следует всё остальное: почему контейнер легче VM (нет своего ядра), почему образ для Linux не запустится «как есть» на другом типе процессора (нужна подходящая сборка) и почему контейнер можно ограничить по памяти одной опцией.

### deep Команда по частям
`docker run --rm -m 64m alpine cat /sys/fs/cgroup/memory.max`: `docker run` — создать контейнер и запустить в нём команду; `--rm` — удалить контейнер после завершения; `-m 64m` — потолок памяти 64 МБ (cgroup); `alpine` — имя образа; всё после имени образа (`cat /sys/fs/cgroup/memory.max`) — **команда, которая запустится внутри** контейнера. Файл `/sys/fs/cgroup/memory.max` — «окно» в cgroup: ядро показывает контейнеру только его собственный лимит.

### deep Другие виды namespace
Кроме процессов (`pid`) есть: `net` (своя сетевая карта, свой `localhost`), `mnt` (своя файловая система), `uts` (своё имя хоста), `ipc` (своя межпроцессная память), `user` (свои пользователи), `cgroup`. Docker включает несколько сразу, поэтому контейнер выглядит «целым компьютером». Увидеть их можно у любого процесса Linux в `/proc/<pid>/ns/`.

### deep Если не получилось
- **`Unable to find image 'alpine:latest' locally` и долгая пауза** — это не ошибка: Docker скачивает образ в первый раз. Следующий запуск будет мгновенным.
- **`failed to connect to the docker API` / `Cannot connect to the Docker daemon`** — демон не запущен; шаг 1.7 разбирает, что делать.
- **`memory.max` показывает `max`** — лимит не задан; проверь, что написала `-m 64m` *до* имени образа, а не после.

### quiz
- Кто в цепочке `docker → dockerd → containerd → runc` реально создаёт изолированный процесс?
- Что ограничивает namespace, а что cgroup? Приведи по примеру.
- Почему на Mac команда `uname -sr` внутри контейнера выдаёт `Linux`, а не `Darwin`?

### links
- https://docs.docker.com/get-started/docker-overview/#docker-architecture | архитектура Docker | Docker architecture
- https://man7.org/linux/man-pages/man7/namespaces.7.html | справочник по namespaces | man namespaces(7)

## 1.3 Установка: Docker Desktop, Engine, альтернативы | short: Установка Docker | est: ~30 мин
### intro
**Слова шага:** *Docker Desktop*, *Docker Engine*, *Docker context*, *Compose*, *buildx*, *Colima*, *OrbStack*.

:::tip Если совсем просто
Docker Desktop на Mac — это маленький Linux-домик внутри твоего компьютера. Контейнеры живут там, а у тебя на столе только пульт (`docker`), которым ты ими управляешь.
:::

```svg
<svg viewBox="0 0 640 225" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Docker Desktop на Mac: клиент на Mac, демон в Linux-VM" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m3-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m3-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><rect x="10" y="10" width="620" height="205" rx="8" fill="currentColor" fill-opacity="0.02" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="30" y="32" text-anchor="start" font-size="14" font-weight="700" fill="currentColor" fill-opacity="1">Твой Mac (macOS, ядро Darwin)</text><rect x="30" y="55" width="150" height="60" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="105.0" y="81.0" text-anchor="middle" font-size="13" fill="currentColor">Терминал</text><text x="105.0" y="99.0" text-anchor="middle" font-size="13" fill="currentColor">docker ps</text><rect x="250" y="48" width="365" height="155" rx="8" fill="currentColor" fill-opacity="0.05" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="270" y="70" text-anchor="start" font-size="13" font-weight="700" fill="currentColor" fill-opacity="1">Linux-VM внутри Docker Desktop</text><rect x="275" y="85" width="140" height="44" rx="8" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.5"/><text x="345.0" y="103.0" text-anchor="middle" font-size="13" fill="currentColor">dockerd</text><text x="345.0" y="121.0" text-anchor="middle" font-size="13" fill="currentColor">(демон)</text><rect x="275" y="145" width="80" height="44" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="315.0" y="172.0" text-anchor="middle" font-size="12" fill="currentColor">контейнер</text><rect x="365" y="145" width="80" height="44" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="405.0" y="172.0" text-anchor="middle" font-size="12" fill="currentColor">контейнер</text><rect x="455" y="145" width="80" height="44" rx="8" fill="currentColor" fill-opacity="0.07" stroke="currentColor" stroke-width="1.5"/><text x="495.0" y="172.0" text-anchor="middle" font-size="12" fill="currentColor">контейнер</text><line x1="180" y1="85" x2="275" y2="107" stroke="currentColor" stroke-width="1.8" marker-end="url(#m3-e)"/><text x="227.5" y="89.0" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.85">сокет</text><line x1="345" y1="129" x2="315" y2="145" stroke="currentColor" stroke-width="1.8" marker-end="url(#m3-e)"/><text x="105" y="150" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">клиент: только</text><text x="105" y="168" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.8">отправляет команды</text></svg>
```

Ядро Linux есть только в Linux, а у тебя Mac. Поэтому есть два пути установки:

- **Docker Desktop** (Mac и Windows) — приложение, которое внутри себя прячет лёгкую Linux-VM с **Docker Engine** (демон и всё остальное), а на твоей системе ставит клиент `docker`. Ты общаешься с демоном внутри VM через сокет-файл. В комплекте ещё окошко с контейнерами и образами и настройки ресурсов. Скачать: [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/), выбрать версию под свой процессор (Apple Silicon или Intel).
- **Docker Engine на Linux** — демон ставится прямо в систему (пакет `docker-ce` или скрипт установки с docs.docker.com/engine/install), VM не нужна. Так устроены почти все серверы.

У тебя Docker Desktop уже стоит и запущен: в строке меню Mac виден значок кита. Если значок «пульсирует» — демон ещё стартует, подожди.

**Ресурсы.** Раз контейнеры работают внутри VM, у VM есть потолок памяти, процессоров и диска. Посмотри и при необходимости измени: значок кита → *Settings → Resources*. Для этой лабы хватит 4 ГБ памяти и 2 процессоров; сборки и базы данных любят память, поэтому больше — лучше, но не отбирай всё у самого Mac.

Теперь проверим установку. `docker version` показывает версии обеих половин — клиента и сервера (демона):

```bash
docker version
```

### result
У тебя числа могут быть другими (мы свели вывод к главному). Главное — две части, **Client** и **Server**:

```out
Client:
 Version:           29.5.3
 API version:       1.54
 Go version:        go1.26.4
 OS/Arch:           darwin/arm64
 Context:           desktop-linux

Server: Docker Desktop 4.79.0 (230596)
 Engine:
  Version:          29.5.3
  API version:      1.54 (minimum version 1.40)
  OS/Arch:          linux/arm64
 containerd:
  Version:          v2.2.5
 runc:
  Version:          1.3.6
 docker-init:
  Version:          0.19.0
```

Построчно: **Client / OS/Arch `darwin/arm64`** — клиент работает на Mac с процессором Apple Silicon. **Server / OS/Arch `linux/arm64`** — демон работает на *Linux*, внутри VM Docker Desktop (та самая картина из шага 1.2). **API version** — «язык», на котором клиент и демон общаются; если клиент слишком новый для демона, они договариваются о минимальной общей версии. **containerd** и **runc** — те самые звенья цепочки из шага 1.2.

Теперь `docker info` — подробнее про устройство демона. Нам нужны несколько его строк:

```bash
docker info
```

```out
Server:
 Containers: 16
  Running: 1
  Paused: 0
  Stopped: 15
 Images: 17
 Server Version: 29.5.3
 Storage Driver: overlayfs
  driver-type: io.containerd.snapshotter.v1
 Logging Driver: json-file
 Cgroup Driver: cgroupfs
 Cgroup Version: 2
 Plugins:
  Volume: local
  Network: bridge host ipvlan macvlan null overlay
  Log: awslogs fluentd gcplogs gelf journald json-file local splunk syslog
```

Эту часть вывода стоит запомнить: **Containers / Images** — сколько всего контейнеров и образов знает демон (у тебя числа свои); **Storage Driver** — как слои образов складываются в файловую систему (сессия 3); **Cgroup Version: 2** — какая версия cgroup используется (в шаге 1.2 ты видела файл именно этой версии); **Plugins / Network** — какие сетевые драйверы доступны (сессия 6); **Logging Driver** — куда пишутся логи контейнеров (сессия 2). Выше в полном выводе `docker info` идёт список плагинов клиента — среди них `compose` (сессии 8–9) и `buildx` (сессия 5).

### why
Если не понимать, что «Docker на Mac — это клиент у тебя и демон в виртуальной машине», дальше возникает целый класс странностей: «почему мои файлы не видны контейнеру», «почему `localhost` не тот», «почему диск заполнен, хотя файлов на Mac нет». Все они объясняются одним предложением: контейнеры живут **в VM**, а не в macOS.

### deep Как ещё можно
- **Colima** (`brew install colima docker`, затем `colima start`) — бесплатная лёгкая Linux-VM с Docker Engine внутри, без графического интерфейса; клиент `docker` ставится отдельно.
- **OrbStack** — быстрая замена Docker Desktop для Mac (меньше памяти, быстрее старт), с тем же клиентом `docker`.
- **Rancher Desktop**, **Podman** — другие движки; команды `podman` почти один-в-один как `docker`.
- **Docker Engine в облачной VM или на сервере** — так будет на продакшне; клиент на Mac можно направить на него через *context* (`docker context`).

Все они дают то же самое — демон с API Docker. Лабе всё равно, какой из них у тебя; важно, чтобы работали `docker version` и `docker run hello-world`.

### deep Что такое context
`docker context ls` показывает, **к какому демону** сейчас подключён клиент. У Docker Desktop есть контекст `desktop-linux` (сокет внутри твоей папки `~/.docker/run/docker.sock`), у Linux-сервера он был бы `default`. Переключиться: `docker context use <имя>`. Если команда `docker` внезапно «не видит» контейнеры, которые ты только что создавала, — первым делом проверь контекст.

### deep Если не получилось
- **Нет значка кита / `docker: command not found`** — Docker Desktop не установлен или ты не открыла его хотя бы раз после установки. Запусти приложение, дождись «Engine running» внизу окна.
- **`failed to connect to the docker API …`** — демон не запущен (шаг 1.7).
- **В `docker info` в Server `ERROR`** — клиент нашёл сокет, но демон не отвечает; перезапусти Docker Desktop из меню кита.
- **Mac тормозит** — слишком много памяти отдано VM; уменьши в *Settings → Resources*.

### quiz
- Где физически работает демон Docker, когда ты используешь Docker Desktop на Mac?
- Что покажет `OS/Arch` у Client и у Server и почему они разные?
- Какие два варианта кроме Docker Desktop ты знаешь, и когда нужен Docker Engine без VM?

### links
- https://docs.docker.com/desktop/setup/install/mac-install/ | установка Docker Desktop на Mac | Install Docker Desktop on Mac
- https://docs.docker.com/engine/install/ | установка Docker Engine | Install Docker Engine

## 1.4 Первый контейнер: hello-world по шагам | short: hello-world | est: ~25 мин
### intro
**Слова шага:** *`docker run`*, *pull*, *`latest`*, *Docker Hub*, *слой*.

:::tip Если совсем просто
`hello-world` — как позвонить в справочную и услышать «Алло, мы работаем!». Больше он ничего не умеет: он нужен, чтобы проверить, что вся цепочка цела.
:::

Запустим самый маленький образ — `hello-world`. Он не нужен для работы, у него одна задача: напечатать приветствие и показать, что вся цепочка из шага 1.2 работает.

```bash run
docker run hello-world
```

### result
Первый запуск начинается с загрузки образа (у тебя строки загрузки могут выглядеть как полоски прогресса), потом идёт приветствие:

```out auto
```

Это приветствие само рассказывает, что произошло. Разберём по шагам:

1. **Клиент `docker` связался с демоном** (сокет, шаг 1.3).
2. **Демон не нашёл образ `hello-world:latest` локально** (`Unable to find image … locally`) и пошёл в registry — Docker Hub. `latest` — тег по умолчанию, когда ты не указала другой (подробнее про теги — сессия 3).
3. **Образ скачался** (`Pulling from library/hello-world`, `Pull complete`) и сохранился на диске. Каждая строка с хэшем вроде `c1ec31eb5944: Pull complete` — один *слой* образа.
4. **Демон создал контейнер и запустил в нём программу** — через `containerd` и `runc`.
5. **Программа напечатала текст, демон перенаправил его в твой терминал**, программа завершилась, а с ней и контейнер.

Теперь посмотрим, что осталось после запуска. Образ остался на диске, а контейнер завершился, но не удалился (мы не добавляли `--rm`):

```bash run
docker images
docker ps -a
```

```out auto
```

`docker images` показывает скачанные образы: имя с тегом (`IMAGE`), короткий идентификатор (`ID`), размер на диске (`DISK USAGE`) и размер самого содержимого (`CONTENT SIZE`); колонку `EXTRA` с буквой `U` Docker ставит образам, которые сейчас использует хотя бы один контейнер (*in Use*); `docker ps -a` — все контейнеры, включая остановленные (`-a` = all). В колонке `STATUS` у нашего `Exited (0)`: `0` — код возврата, «закончил без ошибки». Имя контейнера (`NAMES`) Docker придумал сам — случайное прилагательное и фамилия.

Второй запуск стартует уже без загрузки — образ на месте:

```bash run
docker run hello-world
```

```out auto
```

Убери за собой — контейнеры `hello-world` больше не нужны. Команда `docker container prune` удаляет **все остановленные** контейнеры (спросит подтверждение; `-f` пропускает вопрос):

```bash run
docker container prune -f
```

```out auto
```

:::trap Осторожно с prune
`docker container prune` удалит **все** остановленные контейнеры в Docker, а не только свои. На этом Mac у тебя есть остановленные контейнеры с другими проектами — поэтому `prune` на **твоём** Docker лучше не запускать; удаляй конкретный контейнер по имени: `docker rm <имя>`. Здесь команда выполнена в чистом тестовом Docker, где других контейнеров нет.
:::

### why
Строка `Unable to find image … locally` — самая важная для понимания: **образы живут отдельно от контейнеров**. Скачал один раз — запускай сколько угодно. Контейнер — недолговечная вещь, образ — постоянный. Поэтому после `docker run hello-world` на диске остаются и образ, и остановленный контейнер, и их надо убирать.

### deep Что на самом деле внутри hello-world
Это образ в пару килобайт: в нём нет даже оболочки, только один исполняемый файл `/hello`, который печатает приветствие. Поэтому `docker run hello-world sh` не сработает — в образе нет программы `sh`. Образ может быть настолько маленьким, потому что ему не нужна «система»: ядро общее (шаг 1.2).

### deep Команда по частям
`docker run hello-world`: `docker` — клиент; `run` — подкоманда «создать контейнер из образа и запустить»; `hello-world` — имя образа. Полное имя образа — `docker.io/library/hello-world:latest`: `docker.io` — адрес registry, `library` — «официальные» образы Docker Hub, `hello-world` — имя, `latest` — тег. Docker дописывает недостающее сам.

### deep Если не получилось
- **`failed to connect to the docker API …`** — демон не запущен (шаг 1.7).
- **`pull access denied` или `TLS handshake timeout`** — нет доступа к Docker Hub: проверь интернет, VPN или корпоративный прокси; в Docker Desktop прокси задаётся в *Settings → Resources → Proxies*.
- **`toomanyrequests`** — Docker Hub ограничивает число загрузок без входа в аккаунт; подожди час или выполни `docker login`.

### quiz
- В какой момент Docker скачивает образ и сколько раз он это делает при двух запусках подряд?
- Чем отличаются `docker images` и `docker ps -a`?
- Что означает `Exited (0)` в колонке `STATUS`?

### links
- https://hub.docker.com/_/hello-world | образ hello-world на Docker Hub | hello-world

## 1.5 Linux-минимум для Docker | short: Linux-минимум | est: ~35 мин
### intro
**Слова шага:** *файловая система*, *процесс*, *PID*, *пользователь и права*, *порт*, *`sh`*.

:::tip Если совсем просто
Linux внутри контейнера — как квартира. Папки — комнаты, процессы — жильцы (у каждого свой номер), права — ключи, порты — окошки, в которые стучатся гости.
:::

Внутри контейнера всегда Linux, поэтому нужно знать четыре вещи: файлы, процессы, пользователей и порты. Это минимум; подробно — в Bash Lab, но для Docker хватит и этого. Дальше все команды выполняются внутри временного контейнера Alpine через `sh -c '...'` («запусти оболочку `sh` и выполни такую строку»).

**1. Файловая система — это дерево от корня `/`.** Нет дисков `C:`, есть одно дерево. Ключевые папки: `/etc` (настройки), `/var` (изменяющиеся данные и логи), `/tmp` (временное), `/usr/bin` (программы), `/proc` и `/sys` (окна в ядро, не настоящие файлы).

```bash run
docker run --rm alpine sh -c 'pwd; ls /; cat /etc/os-release | head -2'
```

```out auto
```

`pwd` — где я сейчас (корень `/`), `ls /` — что лежит в корне, `cat /etc/os-release` — что за система внутри (`head -2` оставляет две строки).

**2. Процессы.** Запущенная программа — процесс с номером **PID**. В контейнере главный процесс получает PID 1; когда он завершается, контейнер останавливается (это объясняет `Exited (0)` из шага 1.4). `ps` показывает процессы:

```bash run
docker run --rm alpine sh -c 'sleep 30 & ps; echo готово'
```

```out auto
```

`sleep 30 &` запустил паузу в фоне (`&`); в списке видно `sleep` и сам `ps`.PID 1 у оболочки `sh`: именно она стартует первой, и когда она закончится, контейнер остановится.

**3. Пользователи и права.** У каждого файла есть владелец и права «читать / писать / выполнять» для владельца, группы и остальных. По умолчанию процесс в контейнере работает от **root** (пользователь 0) — всемогущий; в сессии 5 мы научимся этого избегать.

```bash run
docker run --rm alpine sh -c 'id; ls -ld /etc /tmp; touch /tmp/a && ls -l /tmp/a'
```

```out auto
```

`id` — кто я (`uid=0(root)`). В `drwxr-xr-x` первая буква `d` — каталог, потом три тройки `rwx` — права владельца, группы, остальных. `touch` создаёт пустой файл.

**4. Порты.** Программа, которая принимает соединения, «слушает» порт — число от 1 до 65535 (у HTTP это 80, у HTTPS — 443, у PostgreSQL — 5432). Один порт может слушать только одна программа в одной сетевой «комнате» — и у каждого контейнера своя «комната» (namespace `net`, шаг 1.2). Покажем это: запустим слушателя и посмотрим список слушающих портов:

```bash run
docker run --rm alpine sh -c 'nc -l -p 8080 & sleep 1; netstat -tln'
```

```out auto
```

В колонке `Local Address` запись `:::8080` значит «слушаю порт 8080 на всех адресах контейнера» (`:::` — «любой адрес» в записи IPv6; в записи IPv4 это было бы `0.0.0.0:8080`). Снаружи, из твоего Mac, этот порт пока недоступен: у контейнера своя сеть, и «пробросить» порт наружу — отдельное действие (`-p`, сессия 2).

### why
Каждая загадка в Docker сводится к одной из этих четырёх тем: «файл не найден» (путь), «контейнер завершился» (процесс с PID 1 закончился), `permission denied` (права и пользователь), `address already in use` (порт занят). Знать четыре слова — значит читать ошибки с первого раза.

### deep Если не получилось
- **`sh: ... not found`** — в Alpine нет многих привычных программ из Ubuntu (`bash`, `curl`); есть только базовый набор `busybox`. Пользуйся `sh`, а нужное добавляй в образ (сессия 4).
- **`nc: ... can't bind`** — порт уже занят в этом же контейнере; в новом контейнере он свободен.
- **Хочешь «зайти» внутрь и походить руками** — `docker run --rm -it alpine sh` (опции `-it` объяснены в сессии 2); выход — `exit` или [[Ctrl]]+[[D]].

### deep Как ещё можно
Если хочется по-настоящему разобраться с Linux, пройди Bash Lab из этого же курса: там терминал, файлы, права, процессы и конвейеры разобраны подробно. Для Docker из него достаточно ориентироваться в `ls`, `cd`, `cat`, `ps`, `chmod` и читать сообщения об ошибках.

### quiz
- Что произойдёт с контейнером, когда завершится процесс с PID 1?
- Что означает `drwxr-xr-x` в начале строки `ls -l`?
- Почему две программы в разных контейнерах могут слушать один и тот же порт 8080, а в одном контейнере — нет?

### links
- https://docs.docker.com/engine/containers/run/#foreground | запуск контейнера на переднем плане | docker run: foreground

## 1.6 Рабочая папка и проверка инструментов | short: Рабочая папка | est: ~20 мин
### intro
**Слова шага:** *Compose*, *buildx*, *рабочая папка*, *`~`*.

:::tip Если совсем просто
Одна папка для всей лабы — как одна коробка для всех деталей конструктора. Ничего не потеряется.
:::

Эта лаба самостоятельная: никаких готовых файлов от других лаб не нужно, всё создаётся по ходу. Все файлы будут жить в одной папке, чтобы ничего не терялось. Создадим её и перейдём внутрь. `~` — сокращение для твоей домашней папки (`/Users/<имя>` на Mac), `-p` в `mkdir` значит «создай, а если уже есть — не ругайся»:

```bash run
mkdir -p ~/docker-lab
cd ~/docker-lab
pwd
```

```out auto
```

(Путь у тебя будет начинаться с `/Users/<твоё имя>`; в этой методичке команды выполнены в тестовом окружении, где домашняя папка — `/work`.)

Теперь убедимся, что установлены два встроенных расширения клиента, которые понадобятся позже. **Compose** запускает несколько контейнеров из одного файла (сессии 8–9). **buildx** собирает образы современным движком BuildKit (сессия 5).

```bash run
docker compose version
docker buildx version
```

```out auto
```

(Номера версий у тебя будут свои — главное, что команды отвечают.)

Заведи в папке файл-журнал, куда будешь записывать, что узнала, — он пригодится, когда нужно вспомнить команду. Команда ниже *дописывает* строку в конец файла (`>>`), создавая его при необходимости:

```bash run
echo "Сессия 1: клиент -> dockerd -> containerd -> runc" >> ~/docker-lab/notes.md
cat ~/docker-lab/notes.md
```

```out auto
```

### why
Одна рабочая папка на всю лабу — это привычка, а не формальность. В сессии 4 в ней появится `coffeeshop/` с проектом, а в сессии 8 — `compose.yaml`; и если всё разбросано по `~/Downloads` и `~/Desktop`, мы потеряем минимум час на поиск. К тому же Docker Desktop на Mac по умолчанию может подключать к контейнерам папки только из `/Users`, `/Volumes`, `/private` и `/tmp` (сессия 7) — домашняя папка подходит.

### deep Как ещё можно
Если тебе удобнее среда с графическим интерфейсом, открой `~/docker-lab` как проект в VS Code (`code ~/docker-lab`): там есть подсветка Dockerfile и расширение «Docker» с окошком контейнеров. Выбор редактора на лабу не влияет; все команды выполняются в терминале Mac.

### quiz
- Что означает `~` в пути `~/docker-lab`?
- Для чего нужны расширения клиента `compose` и `buildx`?
- Зачем держать все файлы лабы в одной папке?

### links
- https://docs.docker.com/compose/ | документация Docker Compose | Docker Compose
- https://docs.docker.com/build/ | документация сборки образов | Docker Build

## 1.7 🔨 Сломать → починить: демон не запущен | short: Демон не запущен | est: ~20 мин
### intro
**Слова шага:** *сокет*, *`DOCKER_HOST`*, *«Cannot connect to the Docker daemon»*.

:::tip Если совсем просто
Телефон не звонит — ты сначала проверяешь, включён ли он, а не переписываешь номер. Так и здесь: «не могу связаться» — сначала проверь, запущен ли Docker.
:::

Самая частая ошибка новичка — Docker Desktop закрыт или ещё не запустился, а команда `docker` пытается связаться с демоном. Сообщение в разных версиях звучит по-разному: в новых клиентах (Docker 29) оно начинается с `failed to connect to the docker API at …`, в прежних — `Cannot connect to the Docker daemon at … Is the docker daemon running?`. Смысл один. Воспроизведём честно, но безопасно: не будем закрывать твой Docker Desktop, а направим клиент на несуществующий сокет — для клиента разницы нет. Переменная `DOCKER_HOST` указывает клиенту, где искать демон:

```bash run
DOCKER_HOST=unix:///tmp/no-such.sock docker ps
```

### result
```out auto
```

**Читай сообщение справа налево.** Последняя фраза — `connect: no such file or directory`: по этому адресу нет сокета. Перед ней подсказка: `check if the path is correct and if the daemon is running` — «проверь, правильный ли путь и запущен ли демон». И в начале адрес, куда клиент стучался. У тебя на Mac в такой ситуации адрес будет вида `unix:///Users/<имя>/.docker/run/docker.sock` — это сокет Docker Desktop. Значит, ошибка не в твоей команде: клиент в порядке, **демона нет**.

Алгоритм починки на Mac:

1. Посмотри в строку меню: есть ли значок кита? Нет — запусти Docker Desktop из «Программ».
2. Значок есть, но «кит едет» (пульсирует) — демон стартует, подожди 30–60 секунд.
3. Значок есть, а ошибка осталась: проверь, **куда смотрит клиент**:

```bash
docker context ls
echo "DOCKER_HOST=$DOCKER_HOST"
```

   Должна быть выбрана звёздочкой строка `desktop-linux`, а `DOCKER_HOST` — пустой. Если там остался чужой адрес, `unset DOCKER_HOST` или `docker context use desktop-linux`.
4. Не помогло — меню кита → *Restart*, а если и это не помогло — *Troubleshoot → Restart Docker Desktop* (на крайний случай — *Clean / Purge data*, но это стирает все образы и тома!).

Проверка, что починено:

```bash run
docker ps
```

```out auto
```

(Таблица может быть пустой или с твоими контейнерами — главное, что нет ошибки.)

### why
Когда видишь «failed to connect to the docker API» (или «Cannot connect to the Docker daemon»), неважно, что ты хотела запустить: сначала вернись на шаг назад и убедись, что **демон жив**. Так выглядит любая диагностика в Docker: идём по цепочке «клиент → сокет → демон» сверху вниз и проверяем каждое звено. С такой привычкой и ошибки сети, томов и прав в следующих сессиях ловятся быстрее.

### deep Если не получилось
- **`permission denied while trying to connect to the Docker daemon socket`** — на Linux у твоего пользователя нет доступа к сокету: добавь его в группу `docker` (`sudo usermod -aG docker $USER`) и перелогинься. На Mac такого не бывает.
- **Демон запущен, а `docker ps` всё равно ругается** — проверь `docker context ls` и `DOCKER_HOST`: клиент мог быть направлен на другой демон, например на прежний сервер или на Colima.
- **После обновления macOS Docker не стартует** — Docker Desktop нужно обновить до свежей версии, а на время — перезагрузить Mac.

### quiz
- Какое звено цепочки сломано, когда видишь `failed to connect to the docker API`: клиент, сокет или демон?
- Как проверить, к какому демону сейчас подключён клиент?
- Зачем мы направили `DOCKER_HOST` в несуществующий сокет вместо того, чтобы закрыть Docker Desktop?

### outro
:::tip Приёмка сессии 1
- `docker run hello-world` отработал, и ты можешь по шагам пересказать, что при этом произошло.
- Ты можешь нарисовать путь команды: `docker` → `dockerd` → `containerd` → `runc` → процесс.
- Ты можешь объяснить словами: что видит контейнер (namespace), что он может использовать (cgroup) и чьё у него ядро.
- Ты отличаешь `Client` и `Server` в `docker version` и знаешь, где физически работает демон на Mac.
- Ты умеешь диагностировать «демон не запущен» по цепочке клиент → сокет → демон.
- Создана папка `~/docker-lab` с файлом `notes.md`.
:::
