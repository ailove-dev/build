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

svn --non-interactive --message "remove old projects rel" rm $SVN_URL/$PROJECT/rel
svn --non-interactive --message "copy dev -> rel" cp $SVN_URL/$PROJECT/dev $SVN_URL/$PROJECT/rel

#sudo -u svn svn --non-interactive merge $SVN_URL/$PROJECT/dev $WWW_PATH/$PROJECT/repo/rel --accept theirs-full
#sudo -u svn svn --non-interactive resolve $WWW_PATH/$PROJECT/repo/rel --accept theirs-full
#sudo -u svn svn --non-interactive --message "merge dev -> rel" commit $WWW_PATH/$PROJECT/repo
