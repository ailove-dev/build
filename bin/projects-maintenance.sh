#!/bin/sh

PATH="/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin"

MYSQL_HOSTNAME="localhost"
MYSQL_DATABASE="redmine"
MYSQL_USERNAME="root"
MYSQL_PASSWORD=`cat /root/.mysql`
MYSQL="mysql -s -u$MYSQL_USERNAME -p$MYSQL_PASSWORD -D$MYSQL_DATABASE -h$MYSQL_HOSTNAME"

cd /srv/svn

for DIRECTORY in *; do
    [[ -d "$DIRECTORY" ]] || continue
    QUERY="SELECT COUNT(identifier) FROM projects WHERE identifier = \"$DIRECTORY\""
    RESULT=`$MYSQL -e "$QUERY"`

    if test "$RESULT" = "0"; then
	echo >> /var/log/reposman.log
	echo "`date`, projects-maintenance.sh" >> /var/log/reposman.log
	echo "somebody wants to delete $DIRECTORY" >> /var/log/reposman.log
    fi
done
