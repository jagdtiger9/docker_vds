# https://stackoverflow.com/questions/58852571/catch-all-helper-for-makefile-when-the-possible-arguments-can-include-a-colon-ch
include .env

#  См. readme
init:
	docker compose exec fpm /bin/bash -c 'groupadd --gid ${GID} gr${GID}; useradd --shell /bin/bash --uid ${UID} --gid ${GID} -m u${UID}'

# Запуск-остановка-статус сервисов и контейнеров
up:
	$(perms) && ${COMPOSE_BIN} up -d --remove-orphans
down:
	${COMPOSE_BIN} down
ps:
	${COMPOSE_BIN} ps

# Выполнение любых служебных операций внутри php контейнера, без необходимости установки локальных инструментов
# make run CMD="yarn build"
# make run CMD="cd public; yarn install"
run:
	docker compose exec --user ${UID}:${GID} fpm /bin/bash -c 'cd /var/www/${PROJECT}; $(CMD)'
fpm:
	docker compose exec fpm /bin/bash -c '$(CMD)'

# Подключение-отключение phpmyadmin на продакшн
up.pma:
	COMPOSE_PROFILES=debug ${COMPOSE_BIN} up -d
down.pma:
	COMPOSE_PROFILES=debug ${COMPOSE_BIN} down

# Перестроение образов контейнеров, в случае их обновления
build:
	${COMPOSE_BIN} stop
	${COMPOSE_BIN} rm -f
	${COMPOSE_BIN} build
build.nocache:
	${COMPOSE_BIN} stop
	${COMPOSE_BIN} rm -f
	${COMPOSE_BIN} build --no-cache
rebuild:
	${COMPOSE_BIN} stop
#	docker rmi $(docker images -q)
	${COMPOSE_BIN} rm -f
	${COMPOSE_BIN} down -v --remove-orphans
	${COMPOSE_BIN} build --pull --no-cache
	${COMPOSE_BIN} pull
pull:
	${COMPOSE_BIN} pull

perms:
	$(perms)

define perms
    mkdir -p -m 0777 ${DATA_MYSQL} \
    && mkdir -p -m 0777 ${DATA_HOSTS} \
    && mkdir -p -m 0777 ${DATA_LOG} \
    && mkdir -p -m 0777 ${DATA_REDIS} \
    && mkdir -p -m 0777 ${CERTBOT_WEB} \
    && mkdir -p -m 0777 ${CERTBOT_SSL}
endef

tests:
	${COMPOSE_BIN} -f docker-compose.yml run tests

nginx.reload:
	docker compose exec nginx nginx -s reload

certbot.create:
	docker compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d ${DOMAIN}

certbot.renew:
	docker compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d ${DOMAIN}
