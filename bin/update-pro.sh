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
    $SUDO_PATH -u $GIT_USERNAME ssh -o StrictHostKeyChecking=no $GIT_USERNAME@$PROJECT.$PRO_HOSTNAME "cd $WWW_PATH/$PROJECT/repo/master; GIT_SSL_NO_VERIFY=true git fetch origin; GIT_SSL_NO_VERIFY=true git reset --hard origin; GIT_SSL_NO_VERIFY=true git clean -d -f; GIT_SSL_NO_VERIFY=true git checkout; GIT_SSL_NO_VERIFY=true git pull; TAG=$((`GIT_SSL_NO_VERIFY=true git tag -l | wc -l`+1)); GIT_SSL_NO_VERIFY=true git tag $TAG; GIT_SSL_NO_VERIFY=true git push origin --tags; /bin/sh /srv/admin/bin/update-revision.sh $PROJECT master; $SUDO_PATH -u $WWW_USERNAME /srv/admin/bin/update-cache.sh $PROJECT"
else
    $SUDO_PATH -u $SVN_USERNAME ssh -o StrictHostKeyChecking=no $SVN_USERNAME@$PROJECT.$PRO_HOSTNAME "LANG=ru_RU.UTF-8 svn --non-interactive update $WWW_PATH/$PROJECT/repo/rel; /bin/sh /srv/admin/bin/update-revision.sh $PROJECT"
fi
