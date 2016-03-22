FROM ubuntu:14.04.4

MAINTAINER Andrea Manzi <manzolo@libero.it>

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

#Enviornment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M

ENV DEBIAN_FRONTEND noninteractive

ARG DATABASE_PASSWORD=shroot12
ENV DATABASE_PASSWORD $DATABASE_PASSWORD

RUN apt-get update
RUN apt-get -y upgrade

RUN apt-get -y install wget supervisor git \
  curl lynx-cur locate mc acl \
  apache2 libapache2-mod-php5 \
  mysql-server \
  php5-mysql php-apc php5-mcrypt php5-cli php5-pgsql php5-gd php5-curl php5-mcrypt \
  pwgen php-pear php5-dev phpmyadmin

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php5/apache2/php.ini && \
sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini && \
sed -i "s#;date.timezone =#\date.timezone = Europe/Rome#g" /etc/php5/apache2/php.ini && \
sed -i "s#;date.timezone =#\date.timezone = Europe/Rome#g" /etc/php5/cli/php.ini

RUN mkdir -p /var/log/supervisor && \
  supervisord --version
  
# Copy site into place.
COPY www /var/www/site

#########################
#Configurazioni
COPY script/start-apache2.sh /tmp/start-apache2.sh
COPY script/create_mysql_admin_user.sh /tmp/create_mysql_admin_user.sh
COPY script/setup-mysql.sh /tmp/setup-mysql.sh

RUN chmod 755 /tmp/*.sh

COPY config/my.cnf /etc/mysql/conf.d/my.cnf
COPY config/supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY config/supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
COPY config/supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

COPY sql/create_tables.sql /tmp/create_tables.sql

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

RUN /tmp/setup-mysql.sh

# config to enable .htaccess
COPY config/apache_default /etc/apache2/sites-available/000-default.conf
COPY config/phpmyadmin.conf /etc/apache2/conf-available/phpmyadmin.conf

# Enable apache mods.
RUN a2enmod php5
RUN a2enconf phpmyadmin.conf
RUN a2enmod rewrite
RUN php5enmod mcrypt

#Per abilitare l'accesso con root senza password
RUN sed -i "s#// \$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\] = TRUE;#\$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\] = TRUE;#g" /etc/phpmyadmin/config.inc.php
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 80 3306

# COPY volumes for MySQL
VOLUME  ["/etc/mysql", "/var/lib/mysql" ]

CMD ["supervisord"]

#docker build --build-arg DATABASE_PASSWORD=manzolo -t manzolo/lamp:latest .
#docker run -d --name lampserver -p 8080:80 -p 33060:3306 manzolo/lamp:latest
#docker exec -i -t lampserver /bin/bash
#docker run -it manzolo/lamp:latest /bin/bash

#docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)
