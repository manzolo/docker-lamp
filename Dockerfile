FROM ubuntu:latest

MAINTAINER Andrea Manzi <manzolo@libero.it>

RUN apt-get update
RUN apt-get -y upgrade

# Install apache, PHP, and supplimentary programs. curl and lynx-cur are for debugging the container.
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install wget supervisor git \
  curl lynx-cur locate mc acl \
  apache2 libapache2-mod-php5 \
  mysql-server \
  php5-mysql php-apc php5-mcrypt php5-cli php5-pgsql php5-gd php5-curl \
  pwgen php-pear php5-dev phpmyadmin

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php5/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini
RUN sed -i "s#;date.timezone =#\date.timezone = Europe/Rome#g" /etc/php5/apache2/php.ini
RUN sed -i "s#;date.timezone =#\date.timezone = Europe/Rome#g" /etc/php5/cli/php.ini

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Copy site into place.
ADD www /var/www/site

#########################
#Configurazioni
ADD start-apache2.sh /start-apache2.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD my.cnf /etc/mysql/conf.d/my.cnf
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Add MySQL utils
ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
RUN chmod 755 /*.sh

# config to enable .htaccess
ADD apache_default /etc/apache2/sites-available/000-default.conf
ADD phpmyadmin.conf /etc/apache2/conf-available/phpmyadmin.conf

# Enable apache mods.
RUN a2enmod php5
RUN a2enconf phpmyadmin.conf
RUN a2enmod rewrite

#Enviornment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M


RUN sed -i "s#// \$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\] = TRUE;#\$cfg\['Servers'\]\[\$i\]\['AllowNoPassword'\] = TRUE;#g" /etc/phpmyadmin/config.inc.php

# Add volumes for MySQL
VOLUME  ["/etc/mysql", "/var/lib/mysql" ]


EXPOSE 80 3306
CMD ["/run.sh"]
#########################
