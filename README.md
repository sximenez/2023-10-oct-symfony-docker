# Docker

Sources:

- [OpenClassrooms Docker course](https://openclassrooms.com/en/courses/2035766-optimisez-votre-deploiement-en-creant-des-conteneurs-avec-docker/)
- [Oclock](https://oclock.io/blog/7538/deployer-docker-developper-symfony)


## Contents

- [Docker](#docker)
  - [Contents](#contents)
  - [Introduction](#introduction)
  - [General](#general)
    - [Read](#read)
    - [Pull from Docker Hub](#pull-from-docker-hub)
    - [Run/stop a container](#runstop-a-container)
    - [Remove a container](#remove-a-container)
    - [Remove all](#remove-all)
    - [Example: run a Nginx server](#example-run-a-nginx-server)
    - [Create an image (Dockerfile)](#create-an-image-dockerfile)
  - [Symfony container set up](#symfony-container-set-up)
    - [Mysql service](#mysql-service)
    - [Apache dockerfile](#apache-dockerfile)
    - [Apache service](#apache-service)
    - [PHP dockerfile](#php-dockerfile)
    - [PHP service](#php-service)
    - [Composer dockerfile](#composer-dockerfile)
    - [Composer service](#composer-service)

## Introduction

Docker packages applications and their dependencies into `containers`.

Containers emulate a given development environment, like a virtual machine.

Instead of installing dependencies locally, we can simply install Docker and run applications within their containers.

This process allows code to run smoothly everywhere, saving time and solving many compatibility issues (e.g. different OS).

Containers can be **stateful** (e.g. mysql database) or **stateless** (e.g. REST API).

Containers are **immutable**: data inside them can change but not configuration (consistency).

## General

### Read

```terminal
<!-- List images -->
docker images 

<!-- List running containers -->
docker ps

<!-- List all containers -->
docker ps -a
```

### Pull from Docker Hub

```terminal
<!-- Clone image -->
docker pull imageName
```

### Run/stop a container

```terminal
<!-- Run container -->
docker run -it -d imageName

<!-- Stop container -->
docker stop idContainer
```

```terminal
docker run hello-world
```

This commands checks if Docker is running correctly.

### Remove a container

```terminal
docker rm containerId
```

### Remove all

```terminal
docker system prune
```

This command removes all stopped containers, all networks unused by containers, all unused images, and cache.

### Example: run a Nginx server

```terminal
docker run -d -p 8080:80 nginx
docker ps
```

```terminal
docker exec -it idContainer bash
```

This allows to access directories within the container (bash syntax).

### Create an image (Dockerfile)

A Dockerfile is like a `package.json`.

Create a `Dockerfile` file in VSCode.

```docker
# Download an image template
FROM alpine:3.14

# Execute commands
CMD ["echo", "hello world"]
```

```terminal
docker build -t imageName .
docker run imageName
```

## Symfony container set up

### Mysql service

```yml
# docker-compose.yml
# This key creates a network for microservices (e.g. mysql)
networks:
  symfony:
    driver: bridge

# mysql service config
myqsl:
  image: mysql:8.0
  # This key sets port
  ports:
    - 3306:3306
  # This key creates the DB and a user
  environment:
    MYSQL_USER: symfony
    MYSQL_PASSWORD: secret
    MYSQL_DATABASE: symfony
    MYSQL_ROOT_PASSWORD: secret
  # This key persists data, otherwise no storing on DB
  volumes:
    - ./mysql:/var/lib/mysql
  networks:
    - symfony
```

### Apache dockerfile

```dockerfile
# Download the latest image
FROM ubuntu/apache2:latest

# Environment variables
ENV APACHE_RUN_USER=symfony
ENV APACHE_RUN_GROUP=symfony

# Create a code dir for the server 
RUN mkdir -p /var/www/html/public

# Apache config file
COPY apache/default.conf /etc/apache2/sites-available/000-symfony.conf

# Run virtual host
RUN a2ensite 000-symfony.conf

# Apache modules for Symfony
RUN a2enmode rewrite actions alias proxy_fcgi setenvif

RUN cat /etc/apache2/envvars

RUN sed -i "s/www-data/${APACHE_RUN_USER}/g" /etc/apache2/envvars

RUN cat /etc/apache2/envvars

RUN groupadd ${APACHE_RUN_GROUP}

RUN useradd -g ${APACHE_RUN_GROUP} ${APACHE_RUN_USER}
```

### Apache service

```yml
# docker-compose.yml
# Apache config
apache:
  build:
    context: .
    dockerfile: apache.dockerfile
  ports:
    - 8080:80
  volumes:
    - ./src:/var/www/html
  depends_on:
    - mysql
    - php
  networks:
    - symfony
```

### PHP dockerfile

```dockerfile
# Adjust version to need
FROM php:8.2-fpm-alpine

# Adjust variables
ENV PHPUSER=symfony
ENV PHPGROUP=symfony

ENV UID=1000
ENV GID=1000

RUN addgroup -g 1006 --system symfony
RUN adduser -G www-data --system -D -s /bin/sh -u 1006 symfony

RUN mkdir -p /var/www/html/public

RUN docker-php-ext-install pdo pdo_mysql

CMD ["php-fpm"]
```

### PHP service

```yml
# Php config
php:
  build:
    context: .
    dockerfile: php.dockerfile
    args:
      - UID=${UID:-1000}
      - GID=${UID:-1000}
    volumes:
      - ./src:/var/www/html
    networks:
      - symfony
```

### Composer dockerfile

```dockerfile
FROM composer:2

RUN adduser -g www-data -s /bin/sh -D symfony
```

### Composer service

```yml
# Composer config
composer:
  build:
    context: .
    dockerfile: composer.dockerfile
    args:
      - UID=${UID:-1000}
      - GID=${UID:-1000}
  volumes:
    - ./src:/var/www/html
  working_dir: /var/www/html
  networks:
    - symfony
```