# nifi-docker

Учебный стенд для знакомства с Apache NiFi и Kafka: NiFi + NiFi Registry + Postgres + Kafka + Kafka UI.

## Быстрый старт
```sh
docker compose up -d
docker compose ps
```

Остановить стенд:
```sh
docker compose stop
```

Запустить обратно (после `stop` состояние сохраняется):
```sh
docker compose start
```

Удалить контейнеры и сеть:
```sh
docker compose down
```
Затем поднять обратно (с сохранённым состоянием в томах):
```sh
docker compose up -d
```

Удалить ещё и тома (volumes) — полный сброс (деструктивно):
```sh
docker compose down -v
```

### Что сохраняется между перезапусками
- `docker compose stop/start` — сохраняется всё (контейнеры не удаляются).
- `docker compose down` — контейнеры удаляются, но тома (volumes) остаются: сохраняются NiFi (`conf`/`state`), NiFi Registry, Postgres.
- `docker compose down -v` — полный сброс: удаляются и контейнеры, и тома (volumes).

Примечание: в этой конфигурации Kafka-сообщения/топики не сохраняются между `docker compose down` → `up` (чтобы не копить дисковое пространство). Между `stop` → `start` Kafka сохраняется. Пример подключения тома (volume) для Kafka есть в `docker-compose.yml`.

## Адреса и доступы
- NiFi: http://localhost:18443/nifi/ (логин `admin`, пароль `Password123456`)
- NiFi docs: https://nifi.apache.org/documentation/
- Registry: http://localhost:18080/nifi-registry
- Registry docs: https://nifi.apache.org/docs/nifi-registry-docs/
- Kafka UI: http://localhost:8082/
- Kafka UI docs: https://docs.kafka-ui.provectus.io/

## Важно про адреса (внутри Docker и с хоста)
Если вы настраиваете подключение *в NiFi*, то `localhost` почти всегда будет неправильным (NiFi живёт в контейнере).

Используйте имена сервисов из `docker-compose.yml`:
- Postgres (из NiFi): `jdbc:postgresql://postgres:5432/app`
- Kafka (из NiFi): `kafka:29092`
- Registry (из NiFi): `http://registry:18080`

А с локальной машины:
- Postgres: `jdbc:postgresql://localhost:5437/app`
- Kafka: `localhost:9092`

## PostgreSQL
JDBC-драйвер для Postgres лежит в `drivers/` и монтируется в контейнер NiFi как `/opt/nifi/nifi-current/drivers/`.

Параметры для DBCP в NiFi:
- Database Connection URL: `jdbc:postgresql://postgres:5432/app`
- Database Driver Class Name: `org.postgresql.Driver`
- Database Driver Location(s): `/opt/nifi/nifi-current/drivers/postgresql-42.7.4.jar`
- Database User: `postgres`
- Password: `postgres`

### Подключение через DBeaver (удобнее всего)
Postgres проброшен наружу на порт `5437`, поэтому в DBeaver создайте подключение со следующими параметрами:
- Host: `localhost`
- Port: `5437`
- Database: `app`
- Username: `postgres`
- Password: `postgres`

Если DBeaver предложит скачать драйвер — соглашайтесь скачать/установить драйвер PostgreSQL.

Инициализация демо-схем/таблиц:
```sh
docker compose exec -T postgres psql -U postgres -d app -f /nifi-templates/SampleKafka2Postgres.sql
```
Запускайте это после первого старта или после `docker compose down -v` (скрипт не идемпотентный: при повторном запуске будут ошибки про существующие схемы/таблицы).

### Через консоль (если нужно)
Просмотр данных:
```sh
docker compose exec -it postgres bash -c "export PGPASSWORD=postgres; psql -U postgres -d app"
select * from ods.samplekafka2postgres order by id desc limit 10;
```

## Kafka
- С локальной машины (например, для консольных утилит): `localhost:9092`
- Из NiFi (внутри Docker): `kafka:29092`

## Примеры flow (шаблоны)
В `nifi-templates/` лежат примеры:
- `Sample2Kafka.xml` / `Sample2Kafka.json` — публикует сообщения в Kafka topic `Sample2Kafka`
- `SampleKafka2Postgres.json` — читает из Kafka topic `Sample2Kafka` и пишет в Postgres (в `stg.samplekafka2postgres`, затем вызывает `ods.load_samplekafka2postgres()`)

### Памятка: как импортировать Process Group / Flow в NiFi
Файлы нужно загружать через браузер с вашей машины (каталог `nifi-templates/`).

**Вариант 1: шаблон `.xml` (Template)**
1) Откройте NiFi: http://localhost:18443/nifi/
2) В верхнем меню найдите `Templates` → `Upload Template` → выберите файл `nifi-templates/Sample2Kafka.xml`.
3) На канвасе: нажмите правой кнопкой мыши → `Instantiate Template` (или иконка Template на панели) → выберите шаблон → разместите process group на канвасе.

**Вариант 2: flow definition `.json`**
Название пункта может отличаться в зависимости от UI/версии, но смысл один — “загрузить process group/flow definition из файла”:
1) В верхнем меню найдите действие вроде `Upload` / `Import` / `Process Group` → выберите загрузку из файла.
2) Выберите `nifi-templates/SampleKafka2Postgres.json` (или `Sample2Kafka.json`) и разместите process group на канвасе.

После импорта, как правило, нужно:
- перейти внутрь process group;
- включить Controller Services (Configure → `Controller Services` → Enable, или “enable all controller services”);
- затем запустить процессоры.

Рекомендуемый минимальный сценарий:
1) topic `Sample2Kafka` вручную создавать обычно не требуется: он создаётся автоматически при первой попытке записи (если в Kafka включено автосоздание топиков; по умолчанию оно включено). Если по какой-то причине topic не появился — создайте его в Kafka UI.
2) Импортируйте flow в NiFi (в зависимости от UI: import/upload template для `.xml` или import flow definition для `.json`). Если вы импортировали раньше, то после `docker compose down` flow сохранится.
3) Внутри flow включите Controller Services, затем запустите процессоры.

Kafka UI уже настроен в `docker-compose.yml`:
- Cluster name: `Kafka Cluster`
- Bootstrap Servers: `kafka:29092`

## Shared folder (общая папка)
Каталог `shared-folder/` на хосте смонтирован в контейнер NiFi как `/opt/nifi/nifi-current/ls-target` (удобно для ListFile/GetFile).
Если после запуска контейнеров возникают проблемы с правами: `sudo chown -R $USER shared-folder`.

## Полезные команды
```sh
docker compose logs -f nifi
docker compose logs -f kafka
docker compose exec postgres bash
```

Для доступа из NiFi к сервисам на локальной машине используйте `host.docker.internal` вместо `localhost`.

## Если что-то не работает
- NiFi может запускаться 1–3 минуты; смотрите `docker compose logs -f nifi`.
- Если процессор в NiFi не подключается к Kafka/Postgres, проверьте, что используете адреса “из NiFi” (см. раздел про Docker).
- Если порты заняты, измените проброс портов в `docker-compose.yml`.
