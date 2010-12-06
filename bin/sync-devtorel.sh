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

if [ -d "$WWW_PATH/$PROJECT/repo/rel/.git" ]; then
#    cd $WWW_PATH/$PROJECT/repo/rel
#    git merge origin/dev
#    TAG=$((`git tag -l | wc -l`+1));
#    git tag $TAG;
#    echo "tag \"$TAG\" created"
#    git push
#    git push --tags
    echo
else
    svn --non-interactive --message "remove old projects rel" rm $SVN_URL/$PROJECT/rel
    svn --non-interactive --message "copy dev -> rel" cp $SVN_URL/$PROJECT/dev $SVN_URL/$PROJECT/rel
fi
