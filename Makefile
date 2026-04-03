# https://stackoverflow.com/questions/58852571/catch-all-helper-for-makefile-when-the-possible-arguments-can-include-a-colon-ch
include .env

ifndef SERVICE
override SERVICE=fpm
endif

## —— 🎵 🐳 Docker Makefile 🐳 🎵 ——————————————————————————————————
help: ## Print this help screen
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(filter-out .env, $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Docker 🐳: Service containers ————————————————————————————————————————————————————————————————
up: ## Start docker hub services
	$(perms) && ${COMPOSE_BIN} up -d
down: ## Stop docker hub services
	${COMPOSE_BIN} down --remove-orphans
ps: ## Print hub services status
	${COMPOSE_BIN} ps
logs: ## Show live logs
	${COMPOSE_BIN} logs --tail=0 --follow

# Перестроение образов контейнеров, в случае их обновления
build: ## Build docker images
	${COMPOSE_BIN} build
rebuild: ## Build docker images, no cache
	${COMPOSE_BIN} build --pull --no-cache
pull: ## Pull remote docker images
	${COMPOSE_BIN} pull
prune: ## Remove unused images - free disc space
	docker image prune -a

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
    && mkdir -p -m 0777 ${DATA_XDEBUG} \
    && mkdir -p -m 0777 ${NGINX_CACHE} && chmod g+s ${NGINX_CACHE} \
    && mkdir -p -m 0777 ${DATA_LOG} && chmod g+s ${DATA_LOG} \
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

## —— Docker 🐳: Service utilities ————————————————————————————————————————————————————————————————
# Выполнение любых служебных операций внутри php контейнера, без необходимости установки локальных инструментов
# make run CMD="yarn build"
# make run CMD="cd public; yarn install"
run: ## Run a command within PHP-FPM container, for ex: composer install
	docker compose exec --user ${UID}:${GID} fpm /bin/bash -c 'cd /var/www/${PROJECT}; $(CMD)'
nginx.reload: ## Reload proxy service, apply configuration changes
	docker exec proxy ${PROXY_SERVER} -s reload\
init:
	docker compose exec ${SERVICE} /bin/bash -c 'addgroup -g ${GID} g${GID}; adduser -s /bin/bash -u ${UID} -g ${GID} -D u${UID}'
web-user: ## Optional, create host user with the same uid as the web-user
	getent group web-group || sudo groupadd --gid ${WEB_GID} web-group \
		&& getent passwd web-user || sudo useradd --shell /bin/bash --uid ${WEB_UID} --gid ${WEB_GID} -m web-user

## —— Docker 🐳: Database management ————————————————————————————————————————————————————————————————
# БД: дампы, PMA
mysql.create.db: ## Create database
	docker compose exec db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" \
		-e "CREATE DATABASE ${DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql.create.user: ## Create database user
	docker compose exec db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" \
        -e "CREATE USER '${USER}'@'%' IDENTIFIED BY '${PASSWORD}'; GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'%'; FLUSH PRIVILEGES;"
mysql.dump: ## Create database dump
	docker compose exec db mysqldump \
		-u root -p${MYSQL_ROOT_PASSWORD} \
		--single-transaction \
		${DB} > ${FILE}
mysql.restore: ## Restore database dump
	docker compose exec -T db mysql \
		-u root -p${MYSQL_ROOT_PASSWORD} ${DB} < ${FILE}
up.pma: ## PMA service UP
	COMPOSE_PROFILES=debug ${COMPOSE_BIN} up -d
down.pma: ## PMA service DOWN
	COMPOSE_PROFILES=debug ${COMPOSE_BIN} down

## —— Docker 🐳: Virtual hosts ————————————————————————————————————————————————————————————————
# Добавление нового хоста
# make new.host.https HOST="host.domain"
new.host.https: ## Create new HTTPS virtual host
	cp ./config/${PROXY_SERVER}/hosts/default.host.conf_https ${CONF_HOSTS}${HOST}.conf \
	&& sed -i 's/\[DOMAIN_NAME\]/${HOST}/g' ${CONF_HOSTS}${HOST}.conf
# Добавление нового хоста на локальной машине без поддержки SSL
# make new.host HOST="host"
new.host: ## Create new HTTP virtual host
	cp ./config/${PROXY_SERVER}/hosts/default.host.conf_http ${CONF_HOSTS}${HOST}.conf \
	&& sed -i 's/\[DOMAIN_NAME\]/${HOST}/g' ${CONF_HOSTS}${HOST}.conf
certbot.create: ## Create SSL certificate for a given DOMAIN
	docker compose run --rm certbot certonly --keep --webroot --webroot-path /var/www/certbot/ -d ${DOMAIN}
certbot.delete: ## Delete SSL certificate for a given DOMAIN
	docker compose run --rm certbot delete --cert-name ${DOMAIN}
# Задачка в крон для ежемесячной проверки-продления сертификатов
# 17 05     16 * *     project_user   cd ~/work/docker && make certbot.renew && make nginx.reload && echo 'test' >> ~/certbot.log
certbot.renew: ## Update SSL certificate for a given DOMAIN
	docker compose run --rm certbot renew --webroot --webroot-path /var/www/certbot/
certbot.renew.dry: ## Test-update (no real update) SSL certificate for a given DOMAIN
	docker compose run --rm certbot renew --webroot --webroot-path /var/www/certbot/ --dry-run

cert.local.install: ## Create local SSL certificate center
	sudo apt install libnss3-tools \
	&& curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash -\
    && /home/linuxbrew/.linuxbrew/bin/brew shellenv >> ${HOME}/.bash_profile \
	&& brew install mkcert \
	&& mkcert -install
cert.local.create: ## Create SSL certificate for a given local DOMAIN
	mkdir -p .cert && mkcert -key-file ./.cert/${DOMAIN}.key -cert-file ./.cert/${DOMAIN}.crt ${DOMAIN}
