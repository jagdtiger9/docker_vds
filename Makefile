#container=fpm, db, etc...
include .env

up:
	${COMPOSE_BIN} up -d --remove-orphans

build:
	${COMPOSE_BIN} stop
	${COMPOSE_BIN} rm -f
	${COMPOSE_BIN} build

build.nocache:
	${COMPOSE_BIN} stop
	${COMPOSE_BIN} rm -f
	${COMPOSE_BIN} build --no-cache

pull:
	${COMPOSE_BIN} pull

rebuild:
	${COMPOSE_BIN} stop
#	docker rmi $(docker images -q)
	${COMPOSE_BIN} rm -f
	${COMPOSE_BIN} down -v --remove-orphans
	${COMPOSE_BIN} build --pull --no-cache
	${COMPOSE_BIN} pull

down:
	${COMPOSE_BIN} down

ps:
	${COMPOSE_BIN} ps

tests:
	${COMPOSE_BIN} -f docker-compose.yml run tests

clickhouse:
	docker exec -ti clickhouse clickhouse-client

# https://stackoverflow.com/questions/58852571/catch-all-helper-for-makefile-when-the-possible-arguments-can-include-a-colon-ch
fpm:
	docker compose exec fpm /bin/bash -c '$(CMD)'

project.init:
	docker compose exec fpm /bin/bash -c 'useradd --shell /bin/bash --uid ${UID} --gid ${UID} -m u${UID}'

project.user:
	docker compose exec --user ${UID} fpm /bin/bash -c 'cd /var/www/${PROJECT}; $(CMD)'

nginx.reload:
	docker compose exec nginx nginx -s reload

certbot.create:
	docker compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d ${DOMAIN}

certbot.renew:
	docker compose run --rm certbot certonly --webroot --webroot-path /var/www/certbot/ -d ${DOMAIN}
