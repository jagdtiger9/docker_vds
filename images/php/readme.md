docker login --login=...

docker build -f Dockerfile-8.3 -t jagdtiger/php-dev-env-git:php8.3 .

docker push jagdtiger/php-dev-env-git:php8.3

# push images to hub
# https://ropenscilabs.github.io/r-docker-tutorial/04-Dockerhub.html
# https://docs.docker.com/docker-hub/repos/
