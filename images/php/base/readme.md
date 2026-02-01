docker login --login=...

### Build defined php version image
docker build --build-arg PHP_VERSION=8.3 -t jagdtiger/php-dev-env-git:php8.3 .
docker build -f Dockerfile-8.3 -t jagdtiger/php-dev-env-git:php8.3 .

### Push images to hub
docker push jagdtiger/php-dev-env-git:php8.3

# Info
- https://ropenscilabs.github.io/r-docker-tutorial/04-Dockerhub.html
- https://docs.docker.com/docker-hub/repos/
