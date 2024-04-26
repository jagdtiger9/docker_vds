# usage:
# PROJECT=project_name /bin/bash updater.sh

make run PROJECT=${PROJECT} CMD="php cli.php common:updater@update"

#make run PROJECT=${PROJECT} CMD="composer require custom/package @dev"
make run PROJECT=${PROJECT} CMD="composer install --no-dev"
make run PROJECT=${PROJECT} CMD="php cli.php common:migration@run"

make project.init
make run PROJECT=${PROJECT} CMD="yarn install"
make run PROJECT=${PROJECT} CMD="yarn build"
make run PROJECT=${PROJECT} CMD="cd public; yarn install; rm -r vendorjs; mv node_modules vendorjs;"

# check env DB_PORT_MAP param
#mysql -h localhost --protocol=tcp -u root -p ithub_ru < database.sql

# Apply single container changes
# https://stackoverflow.com/questions/31466428/how-to-restart-a-single-container-with-docker-compose/57185184#57185184
