#!/bin/sh

PROJECT="$1"
PROJECT="bepanthen"

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
echo "### execute sync-pro2test.sh on $PROJECT.$PRO_HOSTNAME"
echo
$SUDO_PATH -u $GIT_USERNAME ssh -o StrictHostKeyChecking=no -t $PROJECT.$PRO_HOSTNAME "cd /srv/admin/bin; $SUDO_PATH -u $WWW_USERNAME /srv/admin/bin/sync-pro2test.sh $PROJECT"

MYSQL_BD=`$SUDO_PATH -u $GIT_USERNAME ssh -o StrictHostKeyChecking=no $PROJECT.$PRO_HOSTNAME "find /var/backups/mysql -name \"*.sql.*\" -ctime 0 | grep \"/$PROJECT/\" | head -1"`
POSTGRESQL_BD=`$SUDO_PATH -u $GIT_USERNAME ssh -o StrictHostKeyChecking=no $PROJECT.$PRO_HOSTNAME "find /var/backups/postgresql -name \"*.sql.*\" -ctime 0 | grep \"/$PROJECT/\" | head -1"`

if [ -n "$MYSQL_BD" ]; then
  BDNAME=$MYSQL_BD
  BDTYPE='mysql'
fi
if [ -n "$POSTGRESQL_BD" ]; then
  BDNAME=$POSTGRESQL_BD
  BDTYPE='psql'
fi

echo
echo "### execute update-pro2test.sh on $PROJECT.$TEST_HOSTNAME"
echo

$SUDO_PATH -u $GIT_USERNAME ssh -o StrictHostKeyChecking=no -t $PROJECT.$TEST_HOSTNAME "cd /srv/admin/bin; $SUDO_PATH -u $WWW_USERNAME /srv/admin/bin/update-pro2test.sh $PROJECT $BDTYPE"

