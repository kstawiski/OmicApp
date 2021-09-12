#!/bin/bash
conda init
. ~/.bashrc

# init for persistent
if [ -d "/home/app" ]
then
	if [ "$(ls -A /home/app)" ]; then
     echo "Using persistent data application from /home/app directory."
	else
    echo "Persistent data directory is empty. Initializing app..."
    wget https://github.com/kstawiski/OmicApp/raw/main/templete.zip && unzip templete.zip -d /home/app && rm templete.zip
	chown app -R /home/app
	fi
else
	echo "Directory /home/app not found."
fi


# nignx+php
/usr/sbin/nginx -g "daemon off;" &
mkdir -p /run/
mkdir -p /run/php/
php-fpm7.4 -R -F &

# Rstudio server
rstudio-server start

# Shiny server
shiny-server 2>&1