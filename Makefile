# https://stackoverflow.com/questions/58852571/catch-all-helper-for-makefile-when-the-possible-arguments-can-include-a-colon-ch
include .env

ifndef SERVICE
override SERVICE=fpm
endif

# Запуск-остановка-статус сервисов и контейнеров
up:
	$(perms) && ${COMPOSE_BIN} up -d --remove-orphans
down:
	${COMPOSE_BIN} down
ps:
	${COMPOSE_BIN} ps
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
# https://medium.com/@nielssj/docker-volumes-and-file-system-permissions-772c1aee23ca
# https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
define perms
    mkdir -p -m 0777 ${DATA_MYSQL} \
    && mkdir -p -m 0777 ${DATA_HOSTS} \
    && mkdir -p -m 0777 ${DATA_LOG} && chmod g+s ${DATA_LOG} \
    && mkdir -p -m 0777 ${LOGGER_SERVICE_LOG} \
    && mkdir -p -m 0777 ${LOGGER_CLIENT_LOG} \
    && mkdir -p -m 0777 ${DATA_REDIS} \
    && mkdir -p -m 0777 ${DATA_RABBITMQ} \
    && mkdir -p -m 0777 ${DATA_PROMETHEUS} \
    && mkdir -p -m 0777 ${DATA_GRAFANA} \
    && mkdir -p -m 0777 ${CERTBOT_WEB} \
    && mkdir -p -m 0777 ${CERTBOT_SSL} \
    && mkdir -p -m 0777 ${CONF_HOSTS} \
    && mkdir -p -m 0777 $$(echo ${CONF_CRON} | rev | cut -d"/" -f2- | rev) \
    && touch ${CONF_CRON} \
    && mkdir -p -m 0777 ${CONF_WORKER}
endef

# Добавление нового хоста
# make new.host.https HOST="host.domain"
new.host.https:
	cp ./config/${PROXY_SERVER}/hosts/default.host.conf_https ${CONF_HOSTS}${HOST}.conf \
	&& sed -i 's/\[DOMAIN_NAME\]/${HOST}/g' ${CONF_HOSTS}${HOST}.conf
# Добавление нового хоста на локальной машине без поддержки SSL
# make new.host HOST="host"
new.host:
	cp ./config/${PROXY_SERVER}/hosts/default.host.conf_http ${CONF_HOSTS}${HOST}.conf \
	&& sed -i 's/\[DOMAIN_NAME\]/${HOST}/g' ${CONF_HOSTS}${HOST}.conf
nginx.reload:
	docker compose exec proxy ${PROXY_SERVER} -s reload
nginx_ws.reload:
	docker compose exec proxy_ws ${PROXY_SERVER} -s reload
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

tests:
	${COMPOSE_BIN} -f docker-compose.yml run tests

# Выполнение любых служебных операций внутри php контейнера, без необходимости установки локальных инструментов
# make run CMD="yarn build"
# make run CMD="cd public; yarn install"
run:
	docker compose exec --user ${UID}:${GID} fpm /bin/bash -c 'cd /var/www/${PROJECT}; $(CMD)'
run.cmd:
	docker compose exec --user ${UID}:${GID} ${SERVICE} /bin/bash -c '$(CMD)'
#  См. readme
init:
	docker compose exec ${SERVICE} /bin/bash -c 'addgroup -g ${GID} g${GID}; adduser -s /bin/bash -u ${UID} -g ${GID} -D u${UID}'
prune:
	docker image prune -a
web-user-create:
	getent group web-group || sudo groupadd --gid ${WEB_GID} web-group \
		&& getent passwd web-user || sudo useradd --shell /bin/bash --uid ${WEB_UID} --gid ${WEB_GID} -m web-user

# Подключение-отключение phpmyadmin на продакшн
up.pma:
	COMPOSE_PROFILES=debug ${COMPOSE_BIN} up -d
down.pma:
	COMPOSE_PROFILES=debug ${COMPOSE_BIN} down
