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