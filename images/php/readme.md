docker login --login=...

docker build -f Dockerfile-8.2 -t jagdtiger/php-dev-env-git:php8.2 .

docker push jagdtiger/php-dev-env-git:php8.2

# push images to hub
# https://ropenscilabs.github.io/r-docker-tutorial/04-Dockerhub.html
# https://docs.docker.com/docker-hub/repos/