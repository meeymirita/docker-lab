# Сессия 7 · Хранение данных
dur: ~3,5 ч

## 7.1 Данные внутри контейнера умирают вместе с ним | short: Данные умирают | est: ~25 мин
### intro
**Слова шага:** *слой записи*, *анонимный том*, *персистентность*, *`docker volume ls`*.

:::tip Если совсем просто
Контейнер — как номер в гостинице. Всё, что ты оставила в номере, при выезде выкидывают. Если хочешь сохранить вещи, их надо сдать **в камеру хранения** (том) — она живёт отдельно от номера.
:::

Мы знаем (шаги 2.5 и 3.1): всё, что контейнер записывает, лежит в его **слое записи**, который исчезает вместе с контейнером. Для базы данных это катастрофа: удалил контейнер — потерял все данные. Убедимся на настоящей базе. Запустим PostgreSQL, создадим таблицу и запишем строку (`psql -c` выполняет один SQL-запрос):

```bash run
docker run -d --name pg1 -e POSTGRES_PASSWORD=secret postgres:18
sleep 8
docker exec pg1 psql -U postgres -c "CREATE TABLE notes (id serial, text text);"
docker exec pg1 psql -U postgres -c "INSERT INTO notes (text) VALUES ('важная запись');"
docker exec pg1 psql -U postgres -c "SELECT * FROM notes;"
```

### result
```out auto
```

Данные на месте. Теперь «обновим» контейнер — удалим и создадим заново из того же образа:

```bash run
docker rm -f pg1
docker run -d --name pg2 -e POSTGRES_PASSWORD=secret postgres:18
sleep 8
docker exec pg2 psql -U postgres -c "SELECT * FROM notes;"
```

```out auto
```

`relation "notes" does not exist` — таблицы нет: новый контейнер начал с чистого листа. Но куда делись старые данные? Образ PostgreSQL объявляет `VOLUME` (шаг 4.2): Docker автоматически создал для каждого контейнера **анонимный том** со случайным именем. После `docker rm -f` он остался «осиротевшим» — смотрим:

```bash run
docker volume ls
```

```out auto
```

Видны тома с длинными случайными именами: это следы контейнеров `pg1`, `pg2` и контейнеров из прошлых сессий (команда `docker rm` без `-v` тома не удаляет). Данные `pg1` лежат в одном из них, но найти его без имени невозможно. Вывод: **в базе должен быть именованный том**, который мы сами создали и сами подключили (шаг 7.2). Уберём контейнер вместе с его анонимным томом (`-v` — удалить тома, созданные контейнером):

```bash run
docker rm -fv pg2
```

```out auto
```

:::trap Осторожно с «чисткой»
Команда `docker volume prune` удаляет **все тома, которые сейчас не подключены ни к одному контейнеру**, — а значит, и данные остановленных баз других проектов. На твоём Mac лежат тома других проектов, поэтому `prune` здесь не используй: удаляй конкретные тома по имени (`docker volume rm имя`).
:::

### why
Контейнер — «одноразовая» вещь, и это хорошо: образ можно обновить, контейнер пересоздать за секунду. Но данные не должны быть одноразовыми. Поэтому мы **разделяем** эти две вещи: код и окружение живут в образе и контейнере, а данные — в томе, который остаётся при пересоздании.

### deep Команда по частям
`docker exec pg1 psql -U postgres -c "SELECT * FROM notes;"`: `exec` — выполнить команду в работающем контейнере `pg1`; `psql` — клиент PostgreSQL; `-U postgres` — пользователь; `-c "…"` — выполнить этот SQL и выйти. Образ PostgreSQL по умолчанию создаёт пользователя `postgres` с паролем из `POSTGRES_PASSWORD`.

### deep Если не получилось
- **`psql: error: connection to server … failed`** — база ещё стартует; подожди ещё несколько секунд.
- **Таблицы нет и в первом запуске** — команда `CREATE TABLE` не выполнилась; смотри `docker logs pg1`.

### quiz
- Почему после `docker rm` и нового `docker run` таблица пропала?
- Что такое анонимный том и почему его нельзя использовать для данных, которые нужны?
- Почему `docker volume prune` может быть опасным?

### links
- https://docs.docker.com/engine/storage/ | хранение данных | Manage data in Docker
- https://docs.docker.com/reference/cli/docker/volume/ | docker volume | docker volume

## 7.2 Именованные тома | short: Именованные тома | est: ~35 мин
### intro
**Слова шага:** *именованный том (volume)*, *`docker volume create`*, *`-v имя:путь`*, *точка монтирования*, *`/var/lib/postgresql`*.

:::tip Если совсем просто
**Том** — это камера хранения с биркой. Ты сама придумываешь бирку (имя) и говоришь: «Положи мою папку в камеру `coffee-pgdata`». Удалишь номер (контейнер) — камера и вещи в ней остаются. Придёшь с той же биркой — получишь тот же ящик.
:::

```svg
<svg viewBox="0 0 640 250" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Где живут данные: слой записи, том, bind mount, tmpfs" style="max-width:640px;width:100%;height:auto" font-family="inherit"><defs><marker id="m1-e" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="currentColor"/></marker><marker id="m1-s" viewBox="0 0 10 10" refX="1" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M10,0 L0,5 L10,10 z" fill="currentColor"/></marker></defs><rect x="200" y="20" width="240" height="120" rx="8" fill="currentColor" fill-opacity="0.03" stroke="currentColor" stroke-width="1.5" stroke-dasharray="6 4"/><text x="320" y="14" text-anchor="middle" font-size="13" font-weight="700" fill="currentColor" fill-opacity="1">Контейнер</text><rect x="220" y="36" width="200" height="36" rx="8" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="1.5"/><text x="320.0" y="59.0" text-anchor="middle" font-size="12" fill="currentColor">слой записи (умрёт с ним)</text><rect x="220" y="80" width="200" height="40" rx="8" fill="currentColor" fill-opacity="0.04" stroke="currentColor" stroke-width="1.5"/><text x="320.0" y="87.0" text-anchor="middle" font-size="11" fill="currentColor">/var/lib/postgresql</text><text x="320.0" y="105.0" text-anchor="middle" font-size="11" fill="currentColor">/usr/share/nginx/html</text><text x="320.0" y="123.0" text-anchor="middle" font-size="11" fill="currentColor">/cache</text><rect x="10" y="170" width="180" height="60" rx="8" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.5"/><text x="100.0" y="196.0" text-anchor="middle" font-size="12" fill="currentColor">Том (volume)</text><text x="100.0" y="214.0" text-anchor="middle" font-size="12" fill="currentColor">живёт в Docker, отдельно</text><rect x="230" y="170" width="180" height="60" rx="8" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.5"/><text x="320.0" y="196.0" text-anchor="middle" font-size="12" fill="currentColor">Bind mount</text><text x="320.0" y="214.0" text-anchor="middle" font-size="12" fill="currentColor">твоя папка на Mac</text><rect x="450" y="170" width="180" height="60" rx="8" fill="currentColor" fill-opacity="0.14" stroke="currentColor" stroke-width="1.5"/><text x="540.0" y="196.0" text-anchor="middle" font-size="12" fill="currentColor">tmpfs</text><text x="540.0" y="214.0" text-anchor="middle" font-size="12" fill="currentColor">оперативная память</text><line x1="100" y1="170" x2="260" y2="124" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)"/><line x1="320" y1="170" x2="320" y2="124" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)"/><line x1="540" y1="170" x2="380" y2="124" stroke="currentColor" stroke-width="1.8" marker-end="url(#m1-e)"/><text x="70" y="90" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.9">данные переживают</text><text x="70" y="108" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.9">удаление контейнера</text><text x="560" y="90" text-anchor="middle" font-size="12" fill="currentColor" fill-opacity="0.9">исчезают при остановке</text></svg>
```

**Именованный том** — папка, которой управляет Docker; он хранит её отдельно от контейнеров. Создаётся командой `docker volume create` (или автоматически при первом использовании). Подключается ключом `-v имя_тома:путь_в_контейнере`: путь становится **точкой монтирования** — всё, что программа пишет по этому пути, на самом деле попадает в том.

Для PostgreSQL 18 путь важен: **образ ожидает том в `/var/lib/postgresql`** (а сами данные кладёт в подпапку `18/docker`, чтобы упрощать обновления версий). В старых версиях это был `/var/lib/postgresql/data` — об этой разнице мы споткнёмся в шаге 7.7. Создадим том и запустим базу с ним. Заведём в ней пользователя и базу `coffee` — те же, что понадобятся нам в Compose:

```bash run
docker volume create coffee-pgdata
docker run -d --name pg --network none -e POSTGRES_USER=coffee -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=coffee -v coffee-pgdata:/var/lib/postgresql postgres:18
sleep 8
docker exec pg psql -U coffee -d coffee -c "CREATE TABLE notes (id serial, text text);"
docker exec pg psql -U coffee -d coffee -c "INSERT INTO notes (text) VALUES ('эта запись переживёт контейнер');"
```

### result
```out auto
```

(Флаг `--network none` мы поставили, чтобы база никому не была видна по сети: она нам нужна только изнутри через `docker exec`.) Теперь «пересоздадим» контейнер — удалим и запустим новый, подключив **тот же том**:

```bash run
docker rm -f pg
docker run -d --name pg --network none -e POSTGRES_USER=coffee -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=coffee -v coffee-pgdata:/var/lib/postgresql postgres:18
sleep 6
docker exec pg psql -U coffee -d coffee -c "SELECT * FROM notes;"
```

```out auto
```

Запись на месте: контейнер новый, а данные — из тома. (Переменные `POSTGRES_*` при повторном запуске игнорируются: база уже создана.) Осмотрим том:

```bash run
docker volume ls --filter name=coffee
docker volume inspect coffee-pgdata --format 'драйвер: {{.Driver}}{{"\n"}}путь в VM: {{.Mountpoint}}'
docker run --rm -v coffee-pgdata:/data alpine:3.22 ls /data
docker rm -f pg
```

```out auto
```

`Mountpoint` — где том лежит на диске. На Mac это путь **внутри Linux-VM Docker Desktop**, и из терминала Mac напрямую его не открыть. Заглянуть внутрь можно через временный контейнер, подключив том (последняя команда): внутри лежит папка `18` — версия PostgreSQL. Удобно и то, что любой том можно смотреть так же в Docker Desktop, вкладка *Volumes*.

### why
Именованный том — стандартное решение для данных баз, очередей, загруженных файлов. Он не зависит от того, в каком контейнере или даже в каком проекте ты его подключаешь, и его можно бэкапить и переносить (шаг 7.6). Запомни связку: **образ — код, том — данные, контейнер — «мост» между ними.**

### deep Команда по частям
`docker run … -v coffee-pgdata:/var/lib/postgresql postgres:18`: `-v` — подключить том; **до двоеточия** — имя тома; **после двоеточия** — путь внутри контейнера. Если тома с таким именем нет, Docker создаст его сам. Если путь в контейнере уже содержит файлы из образа, при **первом** подключении они копируются в пустой том (так образ может «засеять» начальные данные).

### deep Как ещё можно
- **Список и удаление:** `docker volume ls`, `docker volume rm имя` (удалить можно только неиспользуемый том).
- **Какие контейнеры используют том:** `docker ps -a --filter volume=coffee-pgdata`.
- **Драйверы томов:** `local` (по умолчанию) хранит на диске; существуют плагины для сетевых хранилищ (NFS, облака).
- **Том только для чтения:** `-v coffee-pgdata:/data:ro`.

### deep Если не получилось
- **База «пустая» после пересоздания** — том подключён не по тому пути (для PostgreSQL 18 нужен `/var/lib/postgresql`); см. шаг 7.7.
- **`volume is in use`** (при `rm`) — том подключён к существующему контейнеру; сначала удали контейнер.
- **Хочу «посмотреть файлы тома» на Mac** — напрямую нельзя, только через временный контейнер или вкладку Volumes в Docker Desktop.

### quiz
- Что стоит до и после двоеточия в `-v coffee-pgdata:/var/lib/postgresql`?
- Почему данные в томе переживают `docker rm` контейнера?
- Куда для PostgreSQL 18 нужно монтировать том?

### links
- https://docs.docker.com/engine/storage/volumes/ | тома | Volumes
- https://hub.docker.com/_/postgres | образ postgres | postgres

## 7.3 Bind mount: папка с твоего Mac в контейнер | short: Bind mount | est: ~35 мин
### intro
**Слова шага:** *bind mount*, *`-v путь:путь`*, *`--mount type=bind`*, *`:ro`*, *разработка с «живыми» файлами*.

:::tip Если совсем просто
Bind mount — это **окно** из контейнера в твою папку. Всё, что ты меняешь в папке на Mac, мгновенно видно в контейнере, и наоборот. Волшебство для разработки: поправила файл — обновилась страница, образ пересобирать не нужно.
:::

**Bind mount** подключает к контейнеру **конкретную папку (или файл) с хоста** — не том под управлением Docker. Выглядит так же, как том, но слева — путь (абсолютный, начинается с `/`):

```bash
docker run -v /Users/мира/docker-lab/site:/usr/share/nginx/html:ro nginx
```

`:ro` (read-only) запрещает контейнеру менять файлы — для статического сайта это правильно. В командах ниже путь пишем как `"$PWD/…"` — «текущая папка + …». Покажем «живое» редактирование: подключим нашу страницу сайта к nginx и изменим её, не пересобирая образ:

```bash run
mkdir -p ~/docker-lab/s07/site && cd ~/docker-lab/s07/site
echo '<h1>CoffeeShop: версия 1</h1>' > index.html
docker run -d --name live -p 8085:80 -v "$PWD":/usr/share/nginx/html:ro nginx:1.30-alpine
sleep 2
curl -s http://localhost:8085/
echo '<h1>CoffeeShop: версия 2 (правка без пересборки)</h1>' > index.html
curl -s http://localhost:8085/
```

### result
```out auto
```

Файл на хосте изменили — nginx **сразу** отдал новую страницу: образ не пересобирали, контейнер не перезапускали. Именно так разрабатывают: исходники лежат на хосте, а контейнер их видит. Проверим защиту `:ro` — попробуем изменить файл из контейнера:

```bash run
docker exec live sh -c 'echo "взлом" > /usr/share/nginx/html/index.html'
docker rm -f live
```

```out auto
```

`Read-only file system` — контейнер не может менять смонтированные файлы.

Ловушка bind mount — **несуществующий путь**. Короткий ключ `-v` в этом случае молча **создаёт на хосте пустую папку** с таким именем (даже если ты хотела смонтировать файл!), а длинный `--mount` честно ругается:

```bash run
cd ~/docker-lab/s07
docker run --rm -v "$PWD/nofile.txt":/x.txt alpine:3.22 ls -ld /x.txt
ls -ld nofile.txt
docker run --rm --mount type=bind,src="$PWD/nofile2.txt",dst=/x.txt alpine:3.22 true
```

```out auto
```

В первом случае Docker создал **папку** `nofile.txt` (в выводе `drwxr-xr-x`), хотя ожидался файл, — отсюда типичная ошибка `Is a directory` (шаг 7.7). Во втором `--mount` сообщил: `bind source path does not exist`. Поэтому для bind mount рекомендуют `--mount`: он строже.

### why
Bind mount нужен там, где файлы **живут на хосте** и ты их правишь руками: исходный код при разработке, конфиги, статические сайты. Для данных баз и продакшна выбирай тома: они не зависят от структуры папок хоста и быстрее на Mac.

### deep Подводные камни на Mac
- **Только общие папки.** Docker Desktop монтирует внутрь VM только разрешённые пути (по умолчанию `/Users`, `/Volumes`, `/private`, `/tmp`); остальные нужно добавить в *Settings → Resources → File sharing*.
- **Производительность.** Чтение огромных папок через границу VM (например, `node_modules`) медленнее, чем из тома; `node_modules` держат в образе или в именованном томе.
- **Права.** На Mac Docker Desktop сам согласует владельца файлов; на Linux владелец — тот UID, под которым пишет процесс (шаг 7.5).

### deep Как ещё можно
- **Длинная форма:** `--mount type=bind,src="$PWD",dst=/usr/share/nginx/html,readonly`.
- **Один файл:** `-v "$PWD/nginx.conf":/etc/nginx/conf.d/default.conf:ro` — подменить конфиг без пересборки образа (файл должен существовать!).
- **В Compose:** `volumes: ["./site:/usr/share/nginx/html:ro"]` (сессия 8).

### deep Если не получилось
- **`mounts denied: The path … is not shared`** — папка вне разрешённых путей Docker Desktop: добавь в File sharing.
- **Изменения не видны** — редактор сохраняет файл «через замену», и контейнер держит старый inode; перезапусти контейнер (`docker restart`) или монтируй всю папку, а не один файл.
- **`Is a directory`** — смонтирован несуществующий файл (см. выше).

### quiz
- Чем bind mount отличается от именованного тома?
- Что делает `-v` с несуществующим путём на хосте, а что `--mount`?
- Зачем добавлять `:ro` к монтированию статического сайта?

### links
- https://docs.docker.com/engine/storage/bind-mounts/ | bind mounts | Bind mounts
- https://docs.docker.com/desktop/settings-and-maintenance/settings/#file-sharing | File sharing в Docker Desktop | File sharing

## 7.4 tmpfs, инструкция VOLUME, -v против --mount | short: tmpfs и VOLUME | est: ~30 мин
### intro
**Слова шага:** *tmpfs*, *`VOLUME` в Dockerfile*, *анонимный том*, *`-v`*, *`--mount`*.

:::tip Если совсем просто
`tmpfs` — это **доска для черновиков**: пишешь быстро, но выключили свет — доска чистая. Нужна для временного и секретного, что не должно попасть на диск. А `VOLUME` в рецепте — «автор образа просит: тут будут данные, выдай отдельную камеру хранения».
:::

Три вида хранилищ мы видели; осталось два дополнения.

**1. `tmpfs`** — папка в **оперативной памяти**: очень быстро, на диск ничего не попадает, а при остановке контейнера всё исчезает. Подходит для временных файлов и кэша (мы использовали `--tmpfs /tmp` вместе с `--read-only`, шаг 5.4). Проверим:

```bash run
docker run -d --name tmp1 --tmpfs /cache alpine:3.22 sleep 300
docker exec tmp1 sh -c 'echo "временное" > /cache/data.txt'
docker exec tmp1 cat /cache/data.txt
docker restart tmp1
sleep 1
docker exec tmp1 sh -c 'ls /cache; echo "(содержимое после restart)"'
docker rm -f tmp1
```

### result
```out auto
```

До перезапуска файл читается, после `restart` — папка пуста: tmpfs пересоздан и очищен.

**2. Инструкция `VOLUME`** в Dockerfile объявляет «тут данные»; при запуске Docker сам создаёт для этой папки **анонимный том**. Так сделано в образах PostgreSQL, MySQL и других (в 7.1 мы видели следы). Посмотрим на маленьком образе:

```bash run
mkdir -p ~/docker-lab/s07/vol && cd ~/docker-lab/s07/vol
printf 'FROM alpine:3.22\nVOLUME /data\nCMD ["sleep", "300"]\n' > Dockerfile
docker build -q -t vol:1 . > /dev/null
docker run -d --name v1 vol:1
docker inspect --format '{{range .Mounts}}тип={{.Type}} путь в контейнере={{.Destination}}{{"\n"}}{{end}}' v1
docker rm -f v1
```

```out auto
```

Docker подключил к `/data` анонимный том (`volume`), хотя мы не просили ни `-v`, ни `--mount`. Это удобно как «страховка» (данные не потеряются при пересоздании), но вредно как постоянное решение: том безымянный, и после `docker rm` его не найти (шаг 7.1). Поэтому в продакшне всегда подключают **именованный** том к тому же пути.

**3. `-v` против `--mount`.** Два синтаксиса для одного и того же:

| Задача | Короткая форма `-v` | Длинная форма `--mount` |
|---|---|---|
| именованный том | `-v coffee-pgdata:/var/lib/postgresql` | `--mount type=volume,src=coffee-pgdata,dst=/var/lib/postgresql` |
| bind mount | `-v "$PWD/site":/usr/share/nginx/html:ro` | `--mount type=bind,src="$PWD/site",dst=/usr/share/nginx/html,readonly` |
| tmpfs | `--tmpfs /cache` | `--mount type=tmpfs,dst=/cache` |

`--mount` длиннее, зато читается как словарь и **не создаёт папок молча** (шаг 7.3). `-v` короче и встречается чаще — читать нужно оба.

### why
Теперь у тебя есть полный набор: **том** для данных, **bind mount** для файлов хоста, **tmpfs** для временного. Выбор — вопрос «кто хозяин данных и должны ли они пережить контейнер?». А про `VOLUME` в чужих образах полезно помнить: если не подключить именованный том, данные всё равно уйдут в анонимный.

### deep Команда по частям
`docker run -d --name tmp1 --tmpfs /cache alpine:3.22 sleep 300`: `--tmpfs /cache` — смонтировать `/cache` как tmpfs; `sleep 300` — главный процесс, «усыпляющий» контейнер, чтобы он не завершился. Файл мы пишем отдельной командой `docker exec`, а `docker restart` — останавливает и снова запускает тот же контейнер.

### deep Если не получилось
- **Файл остался после `restart`** — `tmpfs` не указан (запись пошла в слой записи, который переживает `restart`, но не `rm`).
- **`VOLUME` не появился в `inspect`** — в Dockerfile `VOLUME` указан после инструкций, изменяющих эту папку: изменения после `VOLUME` в этой папке пропадают.

### quiz
- Когда подходит tmpfs, а когда том?
- Что делает `VOLUME` в Dockerfile и чем плох анонимный том?
- Чем `--mount` отличается от `-v`?

### links
- https://docs.docker.com/engine/storage/tmpfs/ | tmpfs | tmpfs mounts
- https://docs.docker.com/reference/dockerfile/#volume | VOLUME | Dockerfile VOLUME

## 7.5 Права, UID/GID и docker cp | short: Права и docker cp | est: ~35 мин
### intro
**Слова шага:** *UID*, *GID*, *владелец файла*, *`--user`*, *`docker cp`*, *`chown`*.

:::tip Если совсем просто
У каждого человека в компьютере есть **номер** (UID), и файлы подписаны этим номером, а не именем. Если контейнер работает под номером 1000, а папка принадлежит номеру 0 (root), он в неё не зайдёт, хоть как просись. А если контейнер-«директор» (root) создаст файлы в твоей папке, они окажутся подписаны «директором».
:::

Система Linux различает пользователей по **числам**: `UID` — номер пользователя, `GID` — номер группы. Имена `root`, `node`, `nobody` — лишь удобные ярлыки у конкретных номеров (`root` — 0, `node` в образах Node — 1000). Если файл создан под одним номером, другой пользователь может не иметь на него права. Для bind mount и томов это важно: **владельца определяет процесс, который создал файл**.

Покажем: контейнер от root и контейнер с UID 1000 пишут файлы в одну смонтированную папку (`chmod 777 .` разрешает писать в папку всем — чтобы показать разницу именно во владельцах файлов). Параметр `ls -ln` показывает владельца числами:

```bash run
mkdir -p ~/docker-lab/s07/perm && cd ~/docker-lab/s07/perm
chmod 777 .
docker run --rm -v "$PWD":/out alpine:3.22 sh -c 'echo "от root" > /out/root-file.txt'
docker run --rm --user 1000:1000 -v "$PWD":/out alpine:3.22 sh -c 'echo "от 1000" > /out/user-file.txt'
ls -ln
```

### result
```out auto
```

Файл от контейнера с root (`root-file.txt`) принадлежит UID `0`; созданный с `--user 1000:1000` — UID `1000`. Теперь сломаем и починим. Обычный пользователь с UID 1000 пытается дописать в файл, созданный root:

```bash run
cd ~/docker-lab/s07/perm
docker run --rm --user 1000:1000 -v "$PWD":/out alpine:3.22 sh -c 'echo "дописать" >> /out/root-file.txt'
```

```out auto
```

`Permission denied`: процесс 1000 не может писать в файл root. На **Linux-сервере или в CI** такая ситуация встречается постоянно: контейнер создал файлы под root, а потом ты на хосте не можешь их удалить без `sudo`. Решение — запускать контейнер от своего пользователя: `--user "$(id -u):$(id -g)"` (`id -u` и `id -g` — твои номера). На Mac Docker Desktop сам подгоняет владельцев файлов под твоего пользователя, поэтому проблема проявляется реже, но знать её нужно: тот же Dockerfile потом поедет на Linux.

Теперь **`docker cp`** — копирование файлов между хостом и контейнером (шаг 2.4), но с учётом прав. Копируем в **том**: у тома нет «входа», поэтому берём временный контейнер, подключаем том и копируем в него:

```bash run
cd ~/docker-lab/s07/perm
docker volume create perm-demo
docker create --name helper -v perm-demo:/data alpine:3.22
docker cp root-file.txt helper:/data/
docker run --rm -v perm-demo:/data alpine:3.22 ls -l /data
docker rm helper
docker volume rm perm-demo
```

```out auto
```

`docker create` создаёт контейнер без запуска — его достаточно, чтобы `docker cp` положил файл в подключённый том. Это стандартный приём «положить файл в том».

### why
Права в Docker — не магия, а арифметика номеров. Две практические привычки: **1)** при `chown` и `--user` думай номерами (UID/GID), а не именами; **2)** папку, в которую пишет контейнер, делай принадлежащей тому пользователю, под которым он работает (так в шаге 5.7 мы поправили `/app/data`).

### deep Команда по частям
`ls -ln`: `-l` — подробный список, `-n` — владельца и группу показывать **числами**. `docker run --user 1000:1000`: запустить процесс контейнера под этими UID и GID (имя пользователя в образе при этом не нужно). `docker create --name helper -v perm-demo:/data alpine:3.22` — создать, но не запускать контейнер с подключённым томом.

### deep Как ещё можно
- **Назначить владельца при копировании:** `docker cp --archive …` сохраняет UID/GID источника.
- **Поменять владельца тома одноразовым контейнером:** `docker run --rm -v perm-demo:/data alpine chown -R 1000:1000 /data`.
- **Образ PostgreSQL сам делает `chown`** при первом запуске в пустом томе (его процесс работает под UID 999); поэтому том для БД обычно подключается без забот.

### deep Если не получилось
- **`Permission denied` при записи в bind mount** — владелец папки не совпадает с UID процесса; смени владельца (`chown`) или запусти с `--user`.
- **Файлы на хосте принадлежат root и не удаляются** — их создал контейнер от root; удали одноразовым контейнером (`docker run --rm -v "$PWD":/x alpine rm -rf /x/папка`) или `sudo`.
- **`docker cp` выдаёт `No such container:path`** — перепутан порядок аргументов (`ИСТОЧНИК ЦЕЛЬ`) или забыто двоеточие.

### quiz
- Что такое UID и почему имена пользователей в образе вторичны?
- Почему файлы, созданные контейнером от root в bind mount, потом трудно удалять на Linux?
- Как положить файл в том, у которого нет работающего контейнера?

### links
- https://docs.docker.com/reference/cli/docker/container/run/#user | флаг --user | docker run --user
- https://docs.docker.com/reference/cli/docker/container/cp/ | docker cp | docker container cp

## 7.6 PostgreSQL 18: данные, бэкап и восстановление | short: Бэкап PostgreSQL | est: ~55 мин
### intro
**Слова шага:** *`pg_dump`*, *логический бэкап*, *`/docker-entrypoint-initdb.d`*, *инициализация*, *восстановление*, *`psql`*.

:::tip Если совсем просто
Бэкап — это **копия сейфа на всякий случай**. Мы пишем в файл «рецепт», по которому базу можно собрать заново: какие таблицы и какие строки. Если сейф потерян, из этого файла делаем новый такой же.
:::

Соберём «настоящую» базу CoffeeShop: именованный том для данных (шаг 7.2) и **начальный SQL** — таблица меню. Образ PostgreSQL при самом первом запуске (пока том пуст) выполняет все файлы из папки `/docker-entrypoint-initdb.d`. Положим туда `init.sql` через bind mount (шаг 7.3):

```bash run
mkdir -p ~/docker-lab/coffeeshop/db && cd ~/docker-lab/coffeeshop/db
cat > init.sql <<'EOF'
CREATE TABLE menu (
  id    serial PRIMARY KEY,
  name  text NOT NULL,
  price integer NOT NULL
);

INSERT INTO menu (name, price) VALUES
  ('Эспрессо', 150),
  ('Капучино', 220),
  ('Латте', 250);
EOF
docker volume create coffee-pgdata2
docker run -d --name db --network none -e POSTGRES_USER=coffee -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=coffee -v coffee-pgdata2:/var/lib/postgresql -v "$PWD/init.sql":/docker-entrypoint-initdb.d/init.sql:ro postgres:18
sleep 10
docker exec db psql -U coffee -d coffee -c "SELECT * FROM menu;"
```

### result
```out auto
```

Таблица создана и заполнена самим образом при первом старте. Теперь **бэкап**. `pg_dump` выгружает базу в виде SQL-текста (команды `CREATE` и `INSERT`), а `>` на хосте сохраняет вывод в файл:

```bash run
cd ~/docker-lab/coffeeshop/db
docker exec db pg_dump -U coffee coffee > backup.sql
ls -l backup.sql
grep -E '^(CREATE TABLE|COPY)' backup.sql
```

```out auto
```

В файле `backup.sql` — `CREATE TABLE menu …` и строки данных (в формате `COPY`). Теперь «катастрофа»: удалим и контейнер, **и том** с данными, а потом восстановим базу из бэкапа в совершенно новом контейнере с новым томом:

```bash run
cd ~/docker-lab/coffeeshop/db
docker rm -f db
docker volume rm coffee-pgdata2
docker volume create coffee-pgdata3
docker run -d --name db-restore --network none -e POSTGRES_USER=coffee -e POSTGRES_PASSWORD=secret -e POSTGRES_DB=coffee -v coffee-pgdata3:/var/lib/postgresql postgres:18
sleep 10
echo "--- до восстановления:"
docker exec db-restore psql -U coffee -d coffee -c "SELECT * FROM menu;"
echo "--- восстанавливаем:"
docker exec -i db-restore psql -U coffee -d coffee < backup.sql
echo "--- после восстановления:"
docker exec db-restore psql -U coffee -d coffee -c "SELECT * FROM menu;"
```

```out auto
```

До восстановления таблицы нет (чистая база), после — все три напитка на месте. Строки `SET`, `CREATE TABLE`, `ALTER TABLE` — ответы `psql` на команды из файла; `COPY 3` — загружены три строки. Ключ `-i` у `docker exec -i` оставляет вход открытым, чтобы `< backup.sql` могло передать файл в `psql`. Есть и второй способ бэкапа — **копия самого тома** в архив: подключаем том к временному контейнеру и упаковываем в `.tgz`:

```bash run
cd ~/docker-lab/coffeeshop/db
docker run --rm -v coffee-pgdata3:/data:ro -v "$PWD":/backup alpine:3.22 tar czf /backup/pgdata.tgz -C /data .
ls -lh pgdata.tgz
docker rm -f db-restore
docker volume rm coffee-pgdata3 coffee-pgdata
```

```out auto
```

:::trap Копия тома у работающей базы — ненадёжна
Файлы базы на диске постоянно меняются; архив, снятый «на лету», может оказаться **повреждённым** и не восстановиться. Для работающей PostgreSQL надёжный способ — `pg_dump` (как выше) или остановить базу на время копирования. Копию тома оставляют для остановленных баз и для файловых данных.
:::

### why
Том хранит данные, но **том — не бэкап**: при ошибке в приложении, случайном `DROP TABLE` или выходе из строя диска пропадёт и том. Бэкап — отдельный файл в отдельном месте. Умение сделать `pg_dump` и поднять базу с нуля из этого файла — это и есть «данные не потеряются».

### deep Команда по частям
`docker exec db pg_dump -U coffee coffee > backup.sql`: `pg_dump` — выгрузка; `-U coffee` — пользователь; второй `coffee` — имя базы; `>` — перенаправление вывода в файл на **хосте** (оболочка Mac записывает файл, а не контейнер). `docker exec -i db-restore psql … < backup.sql`: `<` подаёт файл на вход команды; `-i` держит стандартный ввод открытым.

### deep Как ещё можно
- **Сжатый дамп:** `pg_dump -Fc` — формат для `pg_restore` (быстрее на больших базах).
- **Бэкап по расписанию:** `cron` на сервере или отдельный контейнер, который раз в сутки делает `pg_dump` и кладёт файл в другое хранилище.
- **Непрерывное архивирование и PITR** (восстановление на момент времени) — отдельная большая тема; её разбирает PostgreSQL Lab.
- **Выгрузить только структуру:** `pg_dump --schema-only`.

### deep Если не получилось
- **`psql: error: connection … failed` сразу после запуска** — база проходит инициализацию и перезапускается; подожди 10–15 секунд.
- **Скрипт из `initdb.d` не выполнился** — он выполняется **только при пустом томе**: при повторном запуске с готовыми данными его игнорируют. Для повторной проверки удали том.
- **`ERROR: relation "menu" already exists` при восстановлении** — база уже содержит таблицу; восстанавливай в пустую базу.

### quiz
- Когда выполняется `init.sql` из `/docker-entrypoint-initdb.d`, а когда игнорируется?
- Чем бэкап отличается от тома и почему одного тома недостаточно?
- Почему копия файлов тома у работающей базы может не восстановиться?

### links
- https://www.postgresql.org/docs/current/app-pgdump.html | pg_dump | pg_dump
- https://hub.docker.com/_/postgres#initialization-scripts | скрипты инициализации | Initialization scripts

## 7.7 🔨 Сломать → починить: данные пропали, Is a directory | short: Данные пропали | est: ~35 мин
### intro
**Слова шага:** *путь монтирования*, *анонимный том*, *`unused mount/volume`*, *`Is a directory`*.

:::tip Если совсем просто
Три типичные неприятности с хранением. **Не туда положила** вещи (том подключён к другой двери). **Забыла бирку** (том без имени — не найти). **Подсунула папку вместо листа** (вместо файла монтируется папка). Все три видно по одному сообщению.
:::

Три классические поломки. Чиним каждую по сообщению об ошибке.

**Поломка 1: старый путь тома у PostgreSQL 18.** Во многих старых инструкциях и compose-файлах том монтируют в `/var/lib/postgresql/data`. Для PostgreSQL 18 это **неправильный путь**. Запустим «как в старом руководстве»:

```bash run
docker run -d --name pgold -e POSTGRES_PASSWORD=secret -v oldpath:/var/lib/postgresql/data postgres:18
sleep 5
docker ps -a --format 'table {{.Names}}\t{{.Status}}'
docker logs pgold 2>&1 | head -12
```

### result
```out auto
```

Контейнер `Exited (1)`, а в логе всё объяснено. Читай главную мысль: *«in 18+, these Docker images are configured to store database data in … major-version-specific directory names»*, и дальше: *«The suggested container configuration for 18+ is to place a single mount at /var/lib/postgresql»*. Образ видит, что по старому пути `/var/lib/postgresql/data` смонтирован том (в логе: `unused mount/volume`), и отказывается запускаться. **Починка:** монтировать том в `/var/lib/postgresql`:

```bash run
docker rm -fv pgold
docker volume rm oldpath
docker run -d --name pgnew -e POSTGRES_PASSWORD=secret -v newpath:/var/lib/postgresql postgres:18
sleep 8
docker ps --format 'table {{.Names}}\t{{.Status}}'
docker rm -f pgnew
docker volume rm newpath
```

```out auto
```

**Поломка 2: «данные пропали» из-за анонимного тома.** Запуск без `-v` оставляет данные в безымянном томе, который после пересоздания контейнера не подключается (шаг 7.1). Признак: после `docker compose up` или `docker run` база пустая, а `docker volume ls` показывает кучу томов со случайными именами. **Починка:** всегда явный именованный том, а ненужные анонимные — удалить по имени:

```bash run
docker volume ls -q | head -3
```

```out auto
```

**Поломка 3: `Is a directory`.** Мы хотим подключить скрипт `init.sql`, но файл не существует, и `-v` молча создаёт на его месте папку (шаг 7.3). PostgreSQL пытается выполнить «скрипт», а это каталог:

```bash run
mkdir -p ~/docker-lab/s07/trap && cd ~/docker-lab/s07/trap
docker run -d --name pgdir -e POSTGRES_PASSWORD=secret -v pgdir:/var/lib/postgresql -v "$PWD/init.sql":/docker-entrypoint-initdb.d/init.sql postgres:18
sleep 8
docker logs pgdir 2>&1 | grep -i 'directory'
ls -ld init.sql
```

```out auto
```

`could not read from input file: Is a directory` и в папке `drwxr-xr-x … init.sql`: Docker создал **папку** вместо файла. **Починка:** убрать эту «папку-призрак», создать настоящий файл и пересоздать контейнер (том тоже: инициализация выполняется только на пустом томе):

```bash run
cd ~/docker-lab/s07/trap
docker rm -fv pgdir
docker volume rm pgdir
rm -r init.sql
echo "CREATE TABLE hello (i int);" > init.sql
docker run -d --name pgfix -e POSTGRES_PASSWORD=secret -v pgfix:/var/lib/postgresql -v "$PWD/init.sql":/docker-entrypoint-initdb.d/init.sql:ro postgres:18
sleep 8
docker exec pgfix psql -U postgres -c '\dt'
docker rm -fv pgfix
docker volume rm pgfix
```

```out auto
```

Теперь таблица `hello` создана. Итоговое правило хранения для базы: **именованный том к `/var/lib/postgresql`, скрипты инициализации — реальные файлы, подключённые только для чтения**. Уберём анонимные тома, которые остались от наших экспериментов. Названия у них случайные; в тестовом Docker мы можем удалить сразу все «осиротевшие» (`dangling=true` — ни к одному контейнеру не подключены). Пустой список в конце значит, что ничего не осталось:

```bash run
docker volume ls -q | head -20
echo "--- удаляем тома, которые остались без контейнеров:"
docker volume ls -qf dangling=true | xargs -r docker volume rm > /dev/null
docker volume ls -q
```

```out auto
```

:::trap Осторожно!
Последняя команда удалила **все** осиротевшие тома в тестовом Docker. На твоём Mac так делать не надо — там лежат тома других проектов (в том числе базы данных). Удаляй свои по имени: `docker volume rm имя`.
:::

### why
Все три поломки видны из одного взгляда: **сообщение в `docker logs`** и **`docker inspect` / `docker volume ls`**. Научись читать их — и «данные пропали» перестанет быть мистикой: это либо не тот путь, либо безымянный том, либо файл-папка.

### deep Если не получилось
- **Контейнер PostgreSQL перезапускается в цикле** — смотри `docker logs`: чаще всего неправильный путь тома или неполный набор переменных.
- **После `rm` тома база всё равно есть** — контейнер подключён к другому тому; `docker inspect --format '{{json .Mounts}}' имя`.
- **`volume is in use`** — удали сначала контейнеры, использующие том (`docker ps -a --filter volume=имя`).

### quiz
- Куда нужно монтировать том для PostgreSQL 18 и что произойдёт при монтировании в `/var/lib/postgresql/data`?
- Как опознать «осиротевшие» анонимные тома и почему нельзя их чистить `prune` у себя на Mac?
- Что происходит, если смонтировать несуществующий файл через `-v`?

### outro
:::tip Приёмка сессии 7
- Ты объясняешь, почему данные в контейнере умирают, и показываешь это на PostgreSQL.
- Ты создаёшь именованный том, подключаешь его к PostgreSQL 18 (`/var/lib/postgresql`) и показываешь, что данные пережили `docker rm`.
- Ты различаешь том, bind mount и tmpfs, выбираешь подходящий и читаешь оба синтаксиса (`-v` и `--mount`).
- Ты показываешь, как владелец файлов зависит от UID процесса, и можешь положить файл в том через `docker cp`.
- Бэкап `pg_dump` сделан, и база восстановлена из него в новый том.
- Ты чинишь три поломки по сообщению: старый путь тома PostgreSQL 18, анонимный том, `Is a directory`.
:::
