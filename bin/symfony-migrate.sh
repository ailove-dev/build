#!/bin/sh

PROJECT="$1"

PATH=/usr/bin:/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH
LOCATION="$(cd -P -- "$(dirname -- "$0")" && pwd -P)/.."

# read configuration
if [ -f "$LOCATION/etc/project-dev.conf.dist" ]; then
    . "$LOCATION/etc/project-dev.conf.dist"
    if [ -f "$LOCATION/etc/project-dev.conf" ]; then
	. "$LOCATION/etc/project-dev.conf"
    fi
else
    echo "can't load $LOCATION/etc/project-dev.conf.dist, please fetch it from repository"
    exit 0
fi

if [ -z "$PROJECT" ]; then
    echo "use $0 <project>"
    exit 0
fi

if [ -f "$LOCATION/etc/extra-updates.conf.dist" ]; then
    . "$LOCATION/etc/extra-updates.conf.dist"
    if [ -f "$LOCATION/etc/extra-updates.conf" ]; then
	. "$LOCATION/etc/extra-updates.conf"
    fi
fi

$SUDO_PATH -u $SVN_USERNAME ssh -o StrictHostKeyChecking=no $SVN_USERNAME@$DEV2_HOSTNAME "LANG=ru_RU.UTF-8 cd $WWW_PATH/$PROJECT/repo/master; /usr/bin/php app/console -e=prod doctrine:migrations:migrate --no-interaction"
