#!/bin/bash
conda init
. ~/.bashrc

# nignx+php
/usr/sbin/nginx -g "daemon off;" &
mkdir -p /run/
mkdir -p /run/php/
php-fpm7.3 -R -F &

# Rstudio server
rstudio-server start

# Shiny server
shiny-server 2>&1