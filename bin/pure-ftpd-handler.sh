#!/bin/sh

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

if [ -f "$LOCATION/etc/pure-ftpd-handler.conf" ]; then
    . "$LOCATION/etc/pure-ftpd-handler.conf"
else
    echo "can't load $LOCATION/etc/pure-ftpd-handler.conf, please create it"
    exit 0
fi

QUERY_PASSWORD="SELECT u.hashed_password \
    FROM users u \
    JOIN members m ON m.user_id = u.id \
    JOIN projects p ON p.id = m.project_id \
    JOIN member_roles mr ON m.id = mr.member_id \
    JOIN roles r ON r.id = mr.role_id \
    WHERE \
    u.login = SUBSTRING_INDEX('$AUTHD_ACCOUNT','$DELIMITER',1) \
    AND p.identifier = SUBSTRING_INDEX('$AUTHD_ACCOUNT','$DELIMITER',-1) \
    AND ($ACCESS_ROLES) \
    LIMIT 1;"

QUERY_UID="SELECT $WWW_UID"
QUERY_GID="SELECT $WWW_GID"
QUERY_DIR="SELECT CONCAT('$WWW_PATH/', SUBSTRING_INDEX('$AUTHD_ACCOUNT','$DELIMITER',-1))"

QUERY_AUTHD_PASSWORD="SELECT sha1('$AUTHD_PASSWORD')"

RESULT_SHA1_PASSWORD=`$MYSQL -e "$QUERY_PASSWORD"`
RESULT_UID=`$MYSQL -e "$QUERY_UID"`
RESULT_GID=`$MYSQL -e "$QUERY_GID"`
RESULT_DIR=`$MYSQL -e "$QUERY_DIR"`

AUTHD_SHA1_PASSWORD=`$MYSQL -e "$QUERY_AUTHD_PASSWORD"`

if test "$AUTHD_SHA1_PASSWORD" = "$RESULT_SHA1_PASSWORD"; then
    echo "auth_ok:1"
    echo "uid:$RESULT_UID"
    echo "gid:$RESULT_GID"
    echo "dir:$RESULT_DIR"
else
    echo "auth_ok:0"
fi

echo "end"

exit 0
