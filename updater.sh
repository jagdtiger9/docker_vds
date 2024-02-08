# usage:
# PROJECT=project_name bash updater.sh

make project.user PROJECT=${PROJECT} CMD="php cli.php common:updater@update"

#make project.user PROJECT=${PROJECT} CMD="composer require custom/package @dev"
make project.user PROJECT=${PROJECT} CMD="composer install --no-dev"
make project.user PROJECT=${PROJECT} CMD="php cli.php common:migration@run"

make project.init
make project.user PROJECT=${PROJECT} CMD="yarn install"
make project.user PROJECT=${PROJECT} CMD="yarn build"
make project.user PROJECT=${PROJECT} CMD="cd public; yarn install; rm -r vendorjs; mv node_modules vendorjs;"

#mysql -h localhost --protocol=tcp -u root -p ithub_ru < database.sql
