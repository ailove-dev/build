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
exit 1
fi

echo "$PROJECT"

echo
echo "### execute copydb-pro2dev.sh on $PROJECT.$PRO_HOSTNAME"
echo
$SUDO_PATH -u $GIT_USERNAME ssh -o StrictHostKeyChecking=no -t $PROJECT.$PRO_HOSTNAME "cd /srv/admin/scripts; /srv/admin/scripts/copydb_pro2dev $PROJECT"

