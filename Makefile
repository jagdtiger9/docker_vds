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

fpm:
	docker exec -ti php-fpm bash

project:
	docker compose exec --user user fpm /bin/bash -c 'cd /var/www/magicpro; bash ./webInstaller.sh'
# examples:
#  $ docker-composer build --no-cache db
