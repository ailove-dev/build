#!/bin/sh

PROJECT=$1
BRANCH=$2
ACTION=$3

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

$SUDO_PATH -u $WWW_USERNAME /srv/admin/bin/update-cache.sh

if [ ! -d $WWW_PATH/$PROJECT/repo/master ]; then
    GIT_SSL_NO_VERIFY=true git clone $GIT_URL/$PROJECT $WWW_PATH/$PROJECT/repo/master
fi

#cd $WWW_PATH/$PROJECT/repo/master
#GIT_SSL_NO_VERIFY=true git pull

#GIT_SSL_NO_VERIFY=true git branch -a | grep "remotes" | grep -v "HEAD" | while read line
#do
#    BRANCH=`echo $line | awk --field-separator=/ '{print $3}'`
#done

if [ "$ACTION" = "delete" ]; then
    mv $WWW_PATH/$PROJECT/repo/$BRANCH $WWW_PATH/$PROJECT/repo/$BRANCH.removed_by_git
    if [ ! -d $WWW_PATH/$PROJECT/repo/$BRANCH.removed_by_git ]; then
	mkdir $WWW_PATH/$PROJECT/repo/$BRANCH.removed_by_git
    fi
    exit
fi

if [ -d $WWW_PATH/$PROJECT/repo/$BRANCH.removed_by_git ]; then
    rm -rf $WWW_PATH/$PROJECT/repo/$BRANCH.removed_by_git
    exit
fi

if [ ! -d $WWW_PATH/$PROJECT/repo/$BRANCH ]; then
    GIT_SSL_NO_VERIFY=true git clone -b $BRANCH $GIT_URL/$PROJECT $WWW_PATH/$PROJECT/repo/$BRANCH
    exit
fi

cd $WWW_PATH/$PROJECT/repo/$BRANCH
GIT_SSL_NO_VERIFY=true git fetch origin
GIT_SSL_NO_VERIFY=true git reset --hard origin/$BRANCH
GIT_SSL_NO_VERIFY=true git clean -d -f
GIT_SSL_NO_VERIFY=true git checkout
GIT_SSL_NO_VERIFY=true git pull

if [ "$BRANCH" = "master" ]; then
    /srv/admin/bin/update-revision.sh $PROJECT $BRANCH
    exit
fi
