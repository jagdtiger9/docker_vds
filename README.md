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

Если ID пользователя отлично от 1000, необходимо запустить команду инициализации \
_Инициализацию можно запустить только после запуска контейнеров, командой **make up**_

Инициализацию необходимо запускать каждый раз после перестроения (build) контейнеров.

```bash
$ make up
$ make init
$ make down
```

Блок статической конфигурации обычно не требует настройки. \
Блок динамической конфигурации настраивается в случае использования в production или если есть несколько хостов

3. **Директории данных**

В процессе первоначального запуска

- создаются все необходимые директории с данными
- устанавливаются соответствующие права

Если используются кастомные директории, необходимо:

- установить владельцем текущего пользователя
- на директорию БД установить права 0777

4. **Доступ к сервисам извне**

Внешний доступ к определенным сервисам изначально закрыт. \
Доступ к определенным сервисам настраивается с помощью профайлов - **COMPOSE_PROFILES**, - см. docker-compose.yml

## Перенос данных

1. **Nginx**

Конфиги nginx в директорию CONF_HOSTS

2. **Cron**

Для каждого проекта добавляем задачу в созданный после первого запуска файл CONF_CRON
Только команду, без настроек времени и пользователя

```bash
#!/bin/bash

mkdir -p -m 0777 /var/www/magicpro/public/vardata/log/crontab && /usr/bin/php /var/www/magicpro/cli.php >> /var/www/magicpro/public/vardata/log/crontab/cron.log 2>&1
```

3. **Workers**

4. **Certbot**

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

Создаем сертификаты для локальных проектов в директории CERTBOT_SSL(.env), следующими командами:

> openssl req -x509 -new -out magicpro.crt -keyout magicpro.key -days 365 -newkey rsa:4096 -sha256 -nodes

```
Country Name (2 letter code) [AU]:RU
State or Province Name (full name) [Some-State]:Msk
Locality Name (eg, city) []:Msk
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Local
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:magicpro localhost
Email Address []:
```

https://forums.docker.com/t/setup-local-domain-and-ssl-for-php-apache-container/116015/11
