#!/bin/bash
echo "=> Start Apache ..."
source /etc/apache2/envvars
exec apache2 -D FOREGROUND
