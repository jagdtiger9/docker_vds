# https://stackoverflow.com/questions/58852571/catch-all-helper-for-makefile-when-the-possible-arguments-can-include-a-colon-ch
include .env

ifndef SERVICE
#override SERVICE=fpm
override SERVICE=
endif

##
## —— 🎵 🐳 Docker Makefile 🐳 🎵 ——————————————————————————————————
help: ## Print this help screen
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(filter-out .env, $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Install 🚀 ————————————————————————————————————————————————————————————————————————————————————
## 1. Copy .env.example to .env and adjust settings:
##  - UID, GID - use your host user uid/gid: $ id -u; $ id -g
##  - MYSQL_ROOT_PASSWORD, RABBITMQ_PASSWORD, GRAFANA_PASSWORD
##  - HOSTS_CONFIG, HOSTS_DATA - virtual hosts options
## 2. Run: make build && make up
## 3. Run: make web-user (in case WEB_UID/WEB_GID differs from UID/GID)
## 4. Open: http://localhost/ to get more info about virtual hosts settings (fresh install only)
## ...more details: docs/INSTALL.md
##
## —— Docker 🐳: Service containers ————————————————————————————————————————————————————————————————
up: ## Start docker hub services
	$(perms) && ${COMPOSE_BIN} up -d
down: ## Stop docker hub services
	${COMPOSE_BIN} down --remove-orphans
up.profile: ## Start docker hub profile services, [use: PROFILE=...,...]
	${COMPOSE_BIN} --profile ${PROFILE} up -d
down.profile: ## Stop docker hub profile services, [use: PROFILE=...,...]
	${COMPOSE_BIN} --profile ${PROFILE} down --remove-orphans
ps: ## Print hub services status
	${COMPOSE_BIN} ps
# Перестроение образов контейнеров, в случае их обновления
build: ## Build docker images
	${COMPOSE_BIN} build
rebuild: ## Build docker images, no cache
	${COMPOSE_BIN} build --pull --no-cache
pull: ## Pull remote docker images
	${COMPOSE_BIN} pull
prune: ## Remove unused images - free disc space
	docker image prune -a
recreate: ## Restart service with ENV variables updated, [use: SERVICE]
	${COMPOSE_BIN} up -d --force-recreate ${SERVICE}

env.migrate: ## Apply pending .env migrations
	@ver=$$(cat .env.version 2>/dev/null | sed 's/^0*//' || echo 0); \
	[ -z "$$ver" ] && ver=0; \
	latest=$$ver; \
	for f in $$(ls config/env-migrations/*.sh 2>/dev/null | sort -V); do \
		num=$$(basename $$f | cut -d_ -f1 | sed 's/^0*//'); \
		[ -z "$$num" ] && num=0; \
		if [ "$$num" -gt "$$ver" ]; then \
			echo "  → applying $$(basename $$f)..."; \
			bash "$$f" .env && latest=$$num || { echo "  ✗ failed"; exit 1; }; \
		else \
			echo "  ✓ $$(basename $$f) (already applied)"; \
		fi; \
	done; \
	if [ "$$latest" -gt "$$ver" ]; then \
		printf "%04d\n" "$$latest" > .env.version; \
		echo "env.version → $$latest"; \
	else \
		echo "up to date"; \
	fi

perms:
	$(perms)
# Для создания директории крона используется двойной символ $$
# $ в make-файлах - символ определения переменной, для использования в командном контексте его нужно экранировать
# https://stackoverflow.com/questions/74295605/why-call-from-makefile-returns-empty-result-while-same-call-from-console-does-no
# https://medium.com/@nielssj/docker-volumes-and-file-system-permissions-772c1aee23ca
# https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
define perms
    mkdir -p -m 0777 ${DB_DATA} \
    && mkdir -p -m 0777 ${HOSTS_DATA} \
    && mkdir -p -m 0777 ${XDEBUG_DATA} \
    && mkdir -p -m 0777 ${NGINX_CACHE} && chmod g+s ${NGINX_CACHE} \
    && mkdir -p -m 0777 ${DOCKER_LOG} && chmod g+s ${DOCKER_LOG} \
    && mkdir -p -m 0777 ${REDIS_DATA} \
    && mkdir -p -m 0777 ${RABBITMQ_DATA} \
    && mkdir -p -m 0777 ${DATA_PROMETHEUS} \
    && mkdir -p -m 0777 ${DATA_GRAFANA} \
    && mkdir -p -m 0777 ${BACKUP_DATA} \
    && mkdir -p -m 0777 ${CERTBOT_WEB} \
    && mkdir -p -m 0777 ${CERTBOT_SSL} \
    && mkdir -p -m 0777 ${HOSTS_CONFIG} \
    && mkdir -p -m 0777 ${WORKER_CONFIG}
endef

##
## —— Docker 🐳: Service utilities ————————————————————————————————————————————————————————————————
# Выполнение любых служебных операций внутри php контейнера, без необходимости установки локальных инструментов
# make run CMD="yarn build"
# make run CMD="cd public; yarn install"
run: ## Run a command within PHP-FPM container, for ex: composer install, [use: PROJECT(opt), CMD]
	docker compose exec --user ${UID}:${GID} fpm /bin/bash -c 'cd /var/www/${PROJECT}; $(CMD)'
logs: ## Show live logs - all/service, [use: SERVICE(opt)]
	${COMPOSE_BIN} logs --tail=0 --follow ${SERVICE}
logs.clean: ## Remove logrotate .backup files from data/log/
	find ${DOCKER_LOG} -name "*.backup" -delete
nginx.reload: ## Reload proxy service, apply configuration changes
	docker exec proxy ${PROXY_SERVER} -s reload
cron.reload: ## Restart cron container to pick up crontab changes
	${COMPOSE_BIN} up -d --force-recreate cron
init:
	docker compose exec ${SERVICE} /bin/bash -c 'addgroup -g ${GID} g${GID}; adduser -s /bin/bash -u ${UID} -g ${GID} -D u${UID}'
web-user: ## Optional, create host user with the same uid as the web-user
	getent group web-group || sudo groupadd --gid ${WEB_GID} web-group \
		&& getent passwd web-user || sudo useradd --shell /bin/bash --uid ${WEB_UID} --gid ${WEB_GID} -m web-user

##
## —— Docker 🐳: Database management ————————————————————————————————————————————————————————————————
# БД: дампы, PMA
# Выполнение произвольного SQL запроса к БД
# make db.exec SQL="SHOW DATABASES;"
db.exec: ## Execute arbitrary SQL query in db service, [use: SQL]
	docker compose exec db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "${SQL}"
db.create: ## Create database, [use: DB]
	docker compose exec db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" \
		-e "CREATE DATABASE ${DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
db.create.user: ## Create database user, [use: DB, USER, PASSWORD]
	docker compose exec db mysql -u root -p"${MYSQL_ROOT_PASSWORD}" \
        -e "CREATE USER '${USER}'@'%' IDENTIFIED BY '${PASSWORD}'; GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'%'; FLUSH PRIVILEGES;"
db.dump: ## Create database dump, [use: DB, FILE]
	docker compose exec db mysqldump \
		-u root -p${MYSQL_ROOT_PASSWORD} \
		--single-transaction \
		${DB} > ${FILE}
db.restore: ## Restore database dump, [use: DB, FILE]
	docker compose exec -T db mysql \
		-u root -p${MYSQL_ROOT_PASSWORD} ${DB} < ${FILE}
pma.up: ## PMA service UP
	COMPOSE_PROFILES=pma ${COMPOSE_BIN} up -d
pma.down: ## PMA service DOWN
	COMPOSE_PROFILES=pma ${COMPOSE_BIN} down

##
## —— Docker 🐳: Virtual hosts ————————————————————————————————————————————————————————————————
# Добавление нового хоста
# make new.host.https HOST="host.domain"
new.host.https: ## Create new HTTPS virtual host for a given host, [use: HOST]
	cp ./config/nginx/hosts/default.host.conf_https ${HOSTS_CONFIG}${HOST}.conf \
	&& sed -i 's/\[DOMAIN_NAME\]/${HOST}/g' ${HOSTS_CONFIG}${HOST}.conf
# Добавление нового хоста на локальной машине без поддержки SSL
# make new.host HOST="host", [use: HOST]
new.host: ## Create new HTTP virtual host for a given HOST
	cp ./config/nginx/hosts/default.host.conf_http ${HOSTS_CONFIG}${HOST}.conf \
	&& sed -i 's/\[DOMAIN_NAME\]/${HOST}/g' ${HOSTS_CONFIG}${HOST}.conf
cert.create: ## Create SSL certificate for a given DOMAIN, [use: DOMAIN]
	docker compose run --rm --entrypoint certbot certbot certonly --keep --webroot --webroot-path /var/www/certbot/ -d ${DOMAIN}
cert.delete: ## Delete SSL certificate for a given DOMAIN, [use: DOMAIN]
	docker compose run --rm --entrypoint certbot certbot delete --cert-name ${DOMAIN}
# Задачка в крон для ежемесячной проверки-продления сертификатов
# 17 05     16 * *     project_user   cd ~/work/docker && make cert.renew && make nginx.reload && echo 'test' >> ~/certbot.log
cert.renew: ## Update SSL certificate for a given DOMAIN
	docker compose run --rm --entrypoint certbot certbot renew --webroot --webroot-path /var/www/certbot/
cert.renew.dry: ## Test-update (no real update) SSL certificate for a given DOMAIN
	docker compose run --rm --entrypoint certbot certbot renew --webroot --webroot-path /var/www/certbot/ --dry-run

cert.local.install: ## Create local SSL certificate center
	sudo apt install libnss3-tools \
  	&& curl -Lo /tmp/mkcert https://github.com/FiloSottile/mkcert/releases/latest/download/mkcert-v1.4.4-linux-amd64 \
  	&& chmod +x /tmp/mkcert && sudo mv /tmp/mkcert /usr/local/bin/mkcert \
  	&& mkcert -install

cert.local.create: ## Create SSL certificate for a given local DOMAIN, [use: DOMAIN]
	mkdir -p .cert && mkcert -key-file ./.cert/${DOMAIN}.key -cert-file ./.cert/${DOMAIN}.crt ${DOMAIN}

##
## —— Debug 🔧 ————————————————————————————————————————————————————————————————————————————————————
debug.env: ## Print container environment variables, [use: SERVICE]
	docker inspect ${SERVICE} --format '{{.Name}}:{{range .Config.Env}}{{println}}  {{.}}{{end}}{{println}}'
debug.ip: ## Print container IP address(es), [use: SERVICE]
	docker inspect ${SERVICE} --format '{{.Name}}: {{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}{{println}}'
debug.mounts: ## Print container mounts, [use: SERVICE]
	docker inspect ${SERVICE} --format '{{.Name}}:{{range .Mounts}}{{println}}  {{.Type}}: {{.Source}} -> {{.Destination}} {{if .RW}}(rw){{else}}(ro){{end}}{{end}}{{println}}'
debug.ports: ## Print published port mappings, [use: SERVICE]
	docker port ${SERVICE}
debug.state: ## Print container status, health, restarts, [use: SERVICE]
	docker inspect ${SERVICE} --format '{{.Name}}: status={{.State.Status}} started={{.State.StartedAt}} restarts={{.RestartCount}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}-{{end}}{{println}}'

##
## —— Tips 💡 ————————————————————————————————————————————————————————————————————————————————————————
## Basic tips:
##  - Project backup info: ./config/cron/README.md
##  - Full installation guide: docs/INSTALL.md
##  - If you only have one host, always use the name 'magicpro' for it
##  - Any configuration changes made by the user should not be placed in files under Git control
## Basic commands:
##  - Start/stop services: make up / make down
##  - Run command inside PHP container: make run CMD="composer install"
##  - Watch live logs of a service: make logs SERVICE=fpm
##  - Rebuild images without cache: make rebuild
##
