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

# Для создания директории крона используется двойной символ $$
# $ в make-файлах - символ определения переменной, для использования в командном контексте его нужно экранировать
# https://stackoverflow.com/questions/74295605/why-call-from-makefile-returns-empty-result-while-same-call-from-console-does-no
define perms
    mkdir -p -m 0777 ${DATA_MYSQL} \
    && mkdir -p -m 0777 ${DATA_HOSTS} \
    && mkdir -p -m 0777 ${DATA_LOG} \
    && mkdir -p -m 0777 ${DATA_REDIS} \
    && mkdir -p -m 0777 ${DATA_RABBITMQ} \
    && mkdir -p -m 0777 ${CERTBOT_WEB} \
    && mkdir -p -m 0777 ${CERTBOT_SSL} \
    && mkdir -p -m 0777 ${CONF_HOSTS} \
    && mkdir -p -m 0777 ${WS_DATA} \
    && mkdir -p -m 0777 $$(echo ${CONF_CRON} | rev | cut -d"/" -f2- | rev) \
    && touch ${CONF_CRON} \
    && mkdir -p -m 0777 ${CONF_WORKER}
endef

tests:
	${COMPOSE_BIN} -f docker-compose.yml run tests

# Добавление нового хоста
# make new.host HOST="host.domain"
new.host:
	cp ./config/nginx/hosts/default.host.conf_https ${CONF_HOSTS}${HOST}.conf \
	&& sed -i 's/\[DOMAIN_NAME\]/${HOST}/g' ${CONF_HOSTS}${HOST}.conf

nginx.reload:
	docker compose exec nginx nginx -s reload

certbot.create:
	docker compose run --rm certbot certonly --keep --webroot --webroot-path /var/www/certbot/ -d ${DOMAIN}

certbot.delete:
	docker compose run --rm certbot delete --cert-name ${DOMAIN}

# Задачка в крон для ежемесячной проверки-продления сертификатов
# 17 05     16 * *     project_user   cd ~/work/docker && make certbot.renew && make nginx.reload && echo 'test' >> ~/certbot.log
certbot.renew:
	docker compose run --rm certbot renew --webroot --webroot-path /var/www/certbot/
certbot.renew.dry:
	docker compose run --rm certbot renew --webroot --webroot-path /var/www/certbot/ --dry-run

cert.local.install:
	sudo apt install libnss3-tools \
	&& curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash -\
	&& /home/linuxbrew/.linuxbrew/bin/brew shellenv >> ${HOME}/.bash_profile \
	&& brew install mkcert \
	&& mkcert -install

cert.local.create:
	mkdir -p .cert && mkcert -key-file ./.cert/${DOMAIN}.key -cert-file ./.cert/${DOMAIN}.crt ${DOMAIN}
