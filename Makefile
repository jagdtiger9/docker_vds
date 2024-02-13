#container=fpm, db, etc...
include .env

# Выполнение любых служебных операций внутри контейнера, без необходимости установки локальных инструментов
# make run CMD="yarn build"
# make run CMD="cd public; yarn install"
run:
	docker compose exec --user ${UID}:${GID} fpm /bin/bash -c 'cd /var/www/${PROJECT}; $(CMD)'

up:
	$(permissions) && ${COMPOSE_BIN} up -d --remove-orphans

down:
	${COMPOSE_BIN} down

ps:
	${COMPOSE_BIN} ps

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

permissions:
	$(permissions)

define permissions
    mkdir -p -m 0777 ${DATA_MYSQL} && mkdir -p -m 0777 ${DATA_LOG} && mkdir -p -m 0777 ${CERTBOT_WEB} && mkdir -p -m 0777 ${CERTBOT_SSL}
endef

tests:
	${COMPOSE_BIN} -f docker-compose.yml run tests

# https://stackoverflow.com/questions/58852571/catch-all-helper-for-makefile-when-the-possible-arguments-can-include-a-colon-ch
fpm:
	docker compose exec fpm /bin/bash -c '$(CMD)'

container.init:
	docker compose exec fpm /bin/bash -c 'groupadd --gid ${GID} gr${GID}; useradd --shell /bin/bash --uid ${UID} --gid ${GID} -m u${UID}'

nginx.reload:
	docker compose exec nginx nginx -s reload

certbot.create:
	docker compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d ${DOMAIN}

certbot.renew:
	docker compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d ${DOMAIN}
