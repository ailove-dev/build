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

if [ -d "$GIT_REPOSITORIES_PATH/$PROJECT" ]; then
    $SUDO_PATH -u $GIT_USERNAME ssh -o StrictHostKeyChecking=no $PROJECT.$TEST_HOSTNAME "cd $WWW_PATH/$PROJECT/repo/test; GIT_SSL_NO_VERIFY=true git fetch origin; GIT_SSL_NO_VERIFY=true git reset --hard origin/$BRANCH; GIT_SSL_NO_VERIFY=true git pull; /bin/sh /srv/admin/bin/update-revision.sh $PROJECT test"
else
    $SUDO_PATH -u $SVN_USERNAME ssh -o StrictHostKeyChecking=no $PROJECT.$TEST_HOSTNAME "LANG=ru_RU.UTF-8 svn --non-interactive update $WWW_PATH/$PROJECT/repo/test; /bin/sh /srv/admin/bin/update-revision.sh $PROJECT"
fi
