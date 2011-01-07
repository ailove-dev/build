#!/bin/sh

PROJECT=$1
BRANCH=$2

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
    echo "use $0 <project> [git branch]"
    exit 0
fi

if [ -d "$WWW_PATH/$PROJECT/repo/$BRANCH/.git" ]; then
    echo "revision=`cd $WWW_PATH/$PROJECT/repo/$BRANCH && GIT_SSL_NO_VERIFY=true git rev-parse heads/$BRANCH`" > $WWW_PATH/$PROJECT/conf/revision
else
    echo "revision=`LANG=ru_RU.UTF-8 svnversion $WWW_PATH/$PROJECT/repo/dev`" > $WWW_PATH/$PROJECT/conf/revision
fi
