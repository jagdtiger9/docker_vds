# Настройка сервера

## Настройка переменных окружения

1. **Конфигурация**

```bash
# Локальная установка
$ cp .env.example .env
# Публичный сервер
$ cp .env.prod .env
```

_PROJECT_ - название основного проекта, используемого по умолчанию. \
Названием проекта является название его корневой директории расположенной в DATA_HOSTS/ (см .env)

2. **Права доступа**
   _UID_, _GID_ - текущий пользователь, от которого происходит запуск окружения

```bash
# Определение текущего пользователя
$ id -u; id -g
```

Создание пользователей в контейнере происходит автоматически, в момент их запуска. \
Так же можно запустить создание пользователя вручную после запуска контейнеров, командой **make init**

```bash
$ make up
$ make init
```

Блок статической конфигурации обычно не требует настройки. \
Блок динамической конфигурации настраивается в случае использования в production или если есть несколько хостов

3. **Директории данных**

В процессе первоначального запуска

- создаются все необходимые директории с данными
- устанавливаются соответствующие права

Если используются кастомные директории, необходимо:

- установить владельцем текущего пользователя

4. **Доступ к сервисам извне**

Внешний доступ к определенным сервисам изначально закрыт. \
Доступ к определенным сервисам настраивается с помощью профайлов - **COMPOSE_PROFILES**, - см. docker-compose.yml

## Перенос данных

1. **Nginx**

Конфиги nginx в директорию CONF_HOSTS

2. **Database**

```bash
# Via local mysql client (check env DB_PORT_MAP param)
$ mysql -h localhost --protocol=tcp -u root -p db_name < database.sql

# Docker container import
$ docker cp dump_<date>.sql db:/dump.sql
$ docker exec -ti db mysql -u root -p
> use database;
> source /dump.sql;
```

```
SET global general_log = on;
SET global general_log_file='/var/log/mysql/mysql.log';
SET global log_output = 'file'; 
```

3. **Cron**

Для каждого проекта добавляем задачу в созданный после первого запуска файл CONF_CRON
Только команду, без настроек времени и пользователя

```bash
#!/bin/bash

mkdir -p -m 0777 /var/www/magicpro/public/vardata/log/crontab && /usr/bin/php /var/www/magicpro/cli.php >> /var/www/magicpro/public/vardata/log/crontab/cron.log 2>&1
```

4. **Workers**

5. **Certbot**

Если происходит перенос существующего проекта, копируем ssl сертификаты

```bash
# Проверка-обновление сертификатов, раз в месяц, 9-го числа
20 05     09 * *     USER   cd ~/work/docker && make certbot.renew && make nginx.reload && echo `date` - OK >> ~/certbot.log
```

**Сертификаты для локальной разработки**

```bash
#https://habr.com/ru/articles/789442/
#https://habr.com/ru/companies/globalsign/articles/435476/
#https://itsfoss.com/homebrew-linux/
$ make cert.local
```

После успешного создания сертификатов копируем их из директории __.cert__ в директорию ${CERTBOT_SSL}
Используемое для сертификата имя домена - __magicpro.local__ (добавить в /etc/hosts)

# Запуск

1. **Сборка**

```
$ make build
```

2. **Запуск**

```
$ make up
```

### Ошибки во время запуска

```
✘ logger Error                            
Head "https://lg.gpmradio.ru:5050/v2/web/logger/logger/logger/manifests/dev": denied: access forbidden
```

Запускаем команду
> docker login lg.gpmradio.ru:5050

## Выполнение команд в окружении PHP контейнера

```bash
$ make run CMD="yarn build"
$ make run CMD="cd public; yarn install"
```

Если название проекта отличается от указанного в параметре PROJECT переменных окружения, передаем его явно

```bash
$ make run PROJECT="symfony" CMD="yarn build"
$ make run PROJECT="symfony" CMD="cd public; yarn install"
```

## Подключение к сервисам хост машины, на примере mysql-percona

В качестве хоста используем 172.17.0.1, адрес хоста в сети docker0 (по-умолчанию) для linux машин

```bash
create user 'root'@'192.168.17.%' identified by '...';
grant all on *.* to 'root'@'192.168.17.%' with grant option;
```

https://www.techrepublic.com/article/create-mysql-8-database-user-remote-access-databases/

## HTTPS для локальной разработки

```bash
# Устанавливаем необходимые пакеты
$ make cert.local.install
# Создаем локальный сертификат для указанного домена
$ make cert.local DOMAIN=magicpro.local
# Копируем созданные сертификаты в директорию CERTBOT_SSL(.env):
$ cp ./../.cert/ ./data/letsencrypt/
```

https://github.com/FiloSottile/mkcert

## Мониторинг

Grafana dashboards:

- 1860
- 14900
- 8321
- 16310

### mysql-exporter database user

```
CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'password' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
```
