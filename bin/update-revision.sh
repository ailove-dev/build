#!/bin/sh

PROJECT=$1
echo "revision=`LANG=ru_RU.UTF-8 /usr/bin/svnversion /srv/www/$PROJECT/repo/dev`" > /srv/www/$PROJECT/conf/revision
