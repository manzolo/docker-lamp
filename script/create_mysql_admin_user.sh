#!/bin/bash

VOLUME_HOME="/var/lib/mysql"

sed -ri -e "s/^upload_max_filesize.*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" \
    -e "s/^post_max_size.*/post_max_size = ${PHP_POST_MAX_SIZE}/" /etc/php5/apache2/php.ini

/usr/bin/mysqld_safe > /dev/null 2>&1 &

if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."
    mysql_install_db > /dev/null 2>&1
    echo "=> Done!"  
    /tmp/create_mysql_admin_user.sh
else
    echo "=> Using an existing volume of MySQL"
fi


RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MySQL service startup"
    sleep 5
    mysql -uroot -e "status" > /dev/null 2>&1
    RET=$?
done

echo "=> Creating MySQL admin user with $DATABASE_PASSWORD password"

mysql -uroot -e "CREATE USER 'admin'@'%' IDENTIFIED BY '$DATABASE_PASSWORD'"
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION"

# You can create a /mysql-setup.sh file to intialized the DB
if [ -f /mysql-setup.sh ] ; then
  . /mysql-setup.sh
fi

echo "=> Done!"

echo "========================================================================"
echo "You can now connect to this MySQL Server using:"
echo ""
echo "    mysql -uadmin -pDATABASE_PASSWORD -h<host> -P<port>"
echo ""
echo "Please remember to change the above password as soon as possible!"
echo "MySQL user 'root' has no password but only allows local connections"
echo "========================================================================"

echo "=> Installing PhpMyAdmin tables ..."
#setup the phpmyadmin configuration
sed -i "s/\$dbuser=.*/\$dbuser='root';/g" /etc/phpmyadmin/config-db.php
sed -i "s/\$dbpass=.*/\$dbpass='${MYSQL_ENV_MYSQL_ROOT_PASSWORD}';/g" /etc/phpmyadmin/config-db.php
sed -i "s/\$dbserver=.*/\$dbserver='${MYSQL_PORT_3306_TCP_ADDR}';/g" /etc/phpmyadmin/config-db.php
sed -i "s/pma__/pma_/g" /tmp/create_tables.sql
mysql -uroot < /tmp/create_tables.sql
echo "=> Done!"  

mysqladmin -uroot shutdown
