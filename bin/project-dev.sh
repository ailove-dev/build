#!/bin/sh

# factory dev-management script by Igor Olemskoi <igor@southbridge.ru>

ACTION="$1"
PROJECT="$2"

PATH=/usr/bin:/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH
LOCATION="$(cd -P -- "$(dirname -- "$0")" && pwd -P)/.."

# project initialization
if [ "$ACTION" = "init" ]; then
    distcopy() {
	for DISTFILE in *.dist; do
	    if [ -f "$DISTFILE" ]; then
		FILE=`echo $DISTFILE | sed -e 's@.dist@@g'`
		cp -i $DISTFILE $FILE
	    fi
	done
    }
    cd $LOCATION/skel && distcopy
    cd $LOCATION/etc && distcopy
    exit 1
fi

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

# check if mysql is enabled
if [ ! -f "/root/.mysql" ]; then
    MYSQL_ENABLED="NO"
fi

# check if postgresql is enabled
if [ ! -f "/root/.postgresql" ]; then
    POSTGRESQL_ENABLED="NO"
fi

# check if nginx is enabled
if [ ! -d "$NGINX_VIRTUALHOSTS_PATH" ]; then
    NGINX_ENABLED="NO"
fi

# mysql configuration
if [ "$MYSQL_ENABLED" != "NO" ]; then
    MYSQL_USERNAME="root"
    MYSQL_PASSWORD=`cat /root/.mysql`
fi

# generate project password
PASSWORD=`cat /dev/urandom | tr -dc A-Za-z0-9 | head -c8`

OS=`uname`
# sed flags
if [ "$OS" = "FreeBSD" ]; then
    ROOT_USERNAME="root"
    ROOT_GROUP="wheel"
    SED_SUFFIX="-i ''"
    SU_SUFFIX="-fm"
else
    ROOT_USERNAME="root"
    ROOT_GROUP="root"
    SED_SUFFIX="-i"
    SU_SUFFIX="--shell=/bin/sh"
fi

SED_FLAGS="	-e 's@##SUDO_PATH##@$SUDO_PATH@g' \
		-e 's@##SVN_USERNAME##@$SVN_USERNAME@g' \
		-e 's@##SVN_PATH##@$SVN_PATH@g' \
		-e 's@##WWW_PATH##@$WWW_PATH@g' \
		-e 's@##PROJECT##@$PROJECT@g' \
		-e 's@##FACTORY_HOSTNAME##@$FACTORY_HOSTNAME@g' \
		-e 's@##DEV_DOMAIN##@$DEV_HOSTNAME@g' \
		-e 's@##REL_DOMAIN##@$REL_HOSTNAME@g' \
		-e 's@##PRO_DOMAIN##@$PRO_HOSTNAME@g' \
		-e 's@##SVN_URL##@$SVN_URL@g' \
		-e 's@##SKEL_PATH##@$SKEL_PATH@g' \
		-e 's@##PASSWORD##@$PASSWORD@g'"

# if action is not entered
if [ "$ACTION" != "create" -a "$ACTION" != "remove" -a "$ACTION" != "changepass" -a "$ACTION" != "dump" -a "$ACTION" != "zdump" ]; then
    echo "use $0 <create|remove> <project>"
    echo "use $0 <dump|zdump> <project>"
    echo "use $0 <changepass> <mysql|postgresql>"
    echo "use $0 <init>"
    exit 1
fi

# if action "changepass"
if [ "$ACTION" = "changepass" ]; then
    if [ "$PROJECT" = "mysql" ]; then
        if [ "$MYSQL_ENABLED" != "NO" ]; then
            mysqladmin -uroot -p`cat /root/.mysql` password "$PASSWORD"
            echo -n $PASSWORD > /root/.mysql; chmod 0600 /root/.mysql; chown $ROOT_USERNAME:$ROOT_GROUP /root/.mysql
            echo "mysql root password successfully changed, please look at /root/.mysql file"
            exit 0
        else
            echo "mysql is not enabled"
            exit 1
        fi
    elif [ "$PROJECT" = "postgresql" ]; then
        if [ "$POSTGRESQL_ENABLED" != "NO" ]; then
            psql --username=$POSTGRESQL_USERNAME --dbname=postgres --command="ALTER USER root WITH ENCRYPTED PASSWORD '$PASSWORD'"
            echo -n $PASSWORD > /root/.postgresql; chmod 0600 /root/.postgresql; chown $ROOT_USERNAME:$ROOT_GROUP /root/.postgresql
            echo "postgresql root password successfully changed, please look at /root/.postgresql file"
            exit 0
        else
            echo "postgresql is not enabled"
            exit 1
        fi
    else
        echo "no database choosen"
        exit 1
    fi
fi

# if action or project is not entered
if [ -z "$ACTION" -o -z "$PROJECT" ]; then
    echo "use $0 <create|remove> <project>"
    exit 1
fi

# if project name is one of the following
if [ "$PROJECT" = "root" -o "$PROJECT" = "mysql" -o "$PROJECT" = "system" -o "$PROJECT" = "redmine" -o "$PROJECT" = "pureftpd" -o "$PROJECT" = "postgres" -o "$PROJECT" = "pgsql" -o "$PROJECT" = "slack" ]; then
    echo "can't create/remove project 'root', 'mysql', 'postgres', 'pgsql', 'redmine' and 'pureftpd', these project names are forbidden."
    exit 1
fi

# if action "[z]dump"
if [ "$ACTION" = "dump" -o "$ACTION" = "zdump" ]; then
    if [ ! -d "$REPOSITORIES_PATH/$PROJECT" ]; then
	echo "project $PROJECT doesn't exists"
	exit 1
    fi

    if [ "$ACTION" = "zdump" ]; then
	TAR_FLAGS="-jcf"
	TAR_EXT=".tar.bz2"
    else
	TAR_FLAGS="-cf"
	TAR_EXT=".tar"
    fi

    echo "making dump $PROJECT-dump$TAR_EXT..."
    svnadmin dump $REPOSITORIES_PATH/$PROJECT --quiet --incremental >$PROJECT.svn
    mysqldump -u$MYSQL_USERNAME -p$MYSQL_PASSWORD $PROJECT >$PROJECT.mysql
    pg_dump --username=$POSTGRESQL_USERNAME --encoding=utf-8 --clean --no-owner $PROJECT >$PROJECT.pgsql

    tar $TAR_FLAGS $PROJECT-dump$TAR_EXT $PROJECT.svn $PROJECT.mysql $PROJECT.pgsql $WWW_PATH/$PROJECT/conf $WWW_PATH/$PROJECT/data
    rm $PROJECT.svn $PROJECT.mysql $PROJECT.pgsql
    exit 0
fi

# if action "create"
if [ "$ACTION" = "create" ]; then
    # if project already exists
    if [ -d "$REPOSITORIES_PATH/$PROJECT" -o -d "$WWW_PATH/$PROJECT" -o -f "$APACHE_VIRTUALHOSTS_PATH/$PROJECT.$DEV_HOSTNAME.conf" ]; then
	echo "can't create project '$PROJECT' because it already exists."
	exit 1
    fi

    echo "creating project '$PROJECT'"

    ########################################################################################################################
    # create repository
    su $SU_SUFFIX $WWW_USERNAME -c "svnadmin create $REPOSITORIES_PATH/$PROJECT"
    # make first svn checkout
    su $SU_SUFFIX $SVN_USERNAME -c "svn --non-interactive --quiet checkout $SVN_URL/$PROJECT $WWW_PATH/$PROJECT/repo"
    # create svn directories
    su $SU_SUFFIX $SVN_USERNAME -c "svn --non-interactive --quiet mkdir $WWW_PATH/$PROJECT/repo/dev"
    su $SU_SUFFIX $SVN_USERNAME -c "svn --non-interactive --quiet mkdir $WWW_PATH/$PROJECT/repo/dev/htdocs"
    su $SU_SUFFIX $SVN_USERNAME -c "svn --non-interactive --quiet mkdir $WWW_PATH/$PROJECT/repo/rel"
    su $SU_SUFFIX $SVN_USERNAME -c "svn --non-interactive --quiet mkdir $WWW_PATH/$PROJECT/repo/rel/htdocs"
    # make initial commit
    su $SU_SUFFIX $SVN_USERNAME -c "svn --non-interactive --quiet --message \"Initial commit\" commit $WWW_PATH/$PROJECT/repo"

    # copy post-commit hook template

    if [ -f "$SKEL_PATH/post-commit.tpl" ]; then
	su $SU_SUFFIX $WWW_USERNAME -c "cp $SKEL_PATH/post-commit.tpl $REPOSITORIES_PATH/$PROJECT/hooks/post-commit"
    else
	su $SU_SUFFIX $WWW_USERNAME -c "cp $SKEL_PATH/post-commit.tpl.dist $REPOSITORIES_PATH/$PROJECT/hooks/post-commit"
    fi

    # convert template
    eval sed $SED_FLAGS $SED_SUFFIX $REPOSITORIES_PATH/$PROJECT/hooks/post-commit

    # create project's structure and give the rights
    mkdir $WWW_PATH/$PROJECT/tmp
    mkdir $WWW_PATH/$PROJECT/logs
    mkdir $WWW_PATH/$PROJECT/logs/cron
    mkdir $WWW_PATH/$PROJECT/conf
    mkdir $WWW_PATH/$PROJECT/data
    mkdir $WWW_PATH/$PROJECT/cache
    chown -R $WWW_USERNAME:$WWW_USERNAME $WWW_PATH/$PROJECT/tmp; chmod 777 $WWW_PATH/$PROJECT/tmp
    chown -R $ROOT_USERNAME:$ROOT_GROUP $WWW_PATH/$PROJECT/logs; chmod 777 $WWW_PATH/$PROJECT/logs/cron
    chown -R $ROOT_USERNAME:$ROOT_GROUP $WWW_PATH/$PROJECT/conf
    chown -R $WWW_USERNAME:$WWW_USERNAME $WWW_PATH/$PROJECT/data; chmod 777 $WWW_PATH/$PROJECT/data
    chown -R $WWW_USERNAME:$WWW_USERNAME $WWW_PATH/$PROJECT/cache; chmod 777 $WWW_PATH/$PROJECT/cache

    # create revision file
    touch $WWW_PATH/$PROJECT/conf/revision
    chown $SVN_USERNAME:$SVN_USERNAME $WWW_PATH/$PROJECT/conf/revision
    chmod 644 $WWW_PATH/$PROJECT/conf/revision
    echo "revision=`LANG=ru_RU.UTF-8 svnversion $WWW_PATH/$PROJECT/repo/dev`" > $WWW_PATH/$PROJECT/conf/revision

    # generate crontab
    if [ -d "$CROND_PATH" ]; then
	touch $WWW_PATH/$PROJECT/conf/crontab
	chown $ROOT_USERNAME:$ROOT_GROUP $WWW_PATH/$PROJECT/conf/crontab; chmod 644 $WWW_PATH/$PROJECT/conf/crontab
	ln -s $WWW_PATH/$PROJECT/conf/crontab $CROND_PATH/$PROJECT
    fi

    # generate conf/database and chown it
    if [ -f "$SKEL_PATH/database.tpl" ]; then
	cp $SKEL_PATH/database.tpl $WWW_PATH/$PROJECT/conf/database
    else
	cp $SKEL_PATH/database.tpl.dist $WWW_PATH/$PROJECT/conf/database
    fi

    eval sed $SED_FLAGS $SED_SUFFIX $WWW_PATH/$PROJECT/conf/database
    chown $WWW_USERNAME:$WWW_USERNAME $WWW_PATH/$PROJECT/conf/database

    # copy and convert dev & rel virtualhost templates
    if [ -f "$SKEL_PATH/apache-vhost-dev.tpl" ]; then
	cp $SKEL_PATH/apache-vhost-dev.tpl $WWW_PATH/$PROJECT/conf/apache-dev.conf
    else
	cp $SKEL_PATH/apache-vhost-dev.tpl.dist $WWW_PATH/$PROJECT/conf/apache-dev.conf
    fi
    eval sed $SED_FLAGS $SED_SUFFIX $WWW_PATH/$PROJECT/conf/apache-dev.conf

    if [ -f "$SKEL_PATH/apache-vhost-rel.tpl" ]; then
	cp $SKEL_PATH/apache-vhost-rel.tpl $WWW_PATH/$PROJECT/conf/apache-rel.conf
    else
	cp $SKEL_PATH/apache-vhost-rel.tpl.dist $WWW_PATH/$PROJECT/conf/apache-rel.conf
    fi
    eval sed $SED_FLAGS $SED_SUFFIX $WWW_PATH/$PROJECT/conf/apache-rel.conf

    chown $ROOT_USERNAME:$ROOT_GROUP $WWW_PATH/$PROJECT/conf/apache-dev.conf $WWW_PATH/$PROJECT/conf/apache-rel.conf
    ln -s $WWW_PATH/$PROJECT/conf/apache-dev.conf $APACHE_VIRTUALHOSTS_PATH/$PROJECT.$DEV_HOSTNAME.conf
    ln -s $WWW_PATH/$PROJECT/conf/apache-rel.conf $APACHE_VIRTUALHOSTS_PATH/$PROJECT.$REL_HOSTNAME.conf

    if [ "$NGINX_ENABLED" != "NO" ]; then
	if [ -f "$SKEL_PATH/nginx-vhost-dev.tpl" ]; then
	    cp $SKEL_PATH/nginx-vhost-dev.tpl $WWW_PATH/$PROJECT/conf/nginx-dev.conf
	else
	    cp $SKEL_PATH/nginx-vhost-dev.tpl.dist $WWW_PATH/$PROJECT/conf/nginx-dev.conf
	fi
	eval sed $SED_FLAGS $SED_SUFFIX $WWW_PATH/$PROJECT/conf/nginx-dev.conf

	if [ -f "$SKEL_PATH/nginx-vhost-rel.tpl" ]; then
	    cp $SKEL_PATH/nginx-vhost-rel.tpl $WWW_PATH/$PROJECT/conf/nginx-rel.conf
	else
	    cp $SKEL_PATH/nginx-vhost-rel.tpl.dist $WWW_PATH/$PROJECT/conf/nginx-rel.conf
	fi
	eval sed $SED_FLAGS $SED_SUFFIX $WWW_PATH/$PROJECT/conf/nginx-rel.conf

	chown $ROOT_USERNAME:$ROOT_GROUP $WWW_PATH/$PROJECT/conf/nginx-dev.conf $WWW_PATH/$PROJECT/conf/nginx-rel.conf
	ln -s $WWW_PATH/$PROJECT/conf/nginx-dev.conf $NGINX_VIRTUALHOSTS_PATH/$PROJECT.$DEV_HOSTNAME.conf
	ln -s $WWW_PATH/$PROJECT/conf/nginx-rel.conf $NGINX_VIRTUALHOSTS_PATH/$PROJECT.$REL_HOSTNAME.conf
    fi

    # create mysql database and grant access with temporary file
    if [ "$MYSQL_ENABLED" != "NO" ]; then
cat << EOF | mysql -u$MYSQL_USERNAME -p$MYSQL_PASSWORD
SET NAMES UTF8;
CREATE USER '$PROJECT'@'localhost' IDENTIFIED BY '$PASSWORD';
GRANT USAGE ON *.* TO '$PROJECT'@'localhost' IDENTIFIED BY '$PASSWORD' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
GRANT USAGE ON *.* TO '$PROJECT'@'%' IDENTIFIED BY '$PASSWORD' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
CREATE DATABASE IF NOT EXISTS \`$PROJECT\`;
GRANT ALL PRIVILEGES ON \`$PROJECT\`.* TO '$PROJECT'@'localhost';
GRANT ALL PRIVILEGES ON \`$PROJECT\`.* TO '$PROJECT'@'%';
EOF

if [ -f "$SKEL_PATH/wiki-start.tpl" ]; then
    WIKI_START_PATH="$SKEL_PATH/wiki-start.tpl"
else
    WIKI_START_PATH="$SKEL_PATH/wiki-start.tpl.dist"
fi

WIKI_START=`eval sed $SED_FLAGS $WIKI_START_PATH`
cat << EOF | mysql -u$MYSQL_USERNAME -p$MYSQL_PASSWORD -D$REDMINE_DATABASE
SET NAMES UTF8;
CALL create_wiki('$PROJECT', $WIKI_AUTHOR_ID, '$WIKI_START');
EOF
    fi

    # create postgresql username and database, grant access
    if [ "$POSTGRESQL_ENABLED" != "NO" ]; then
	createuser --username=$POSTGRESQL_USERNAME --no-superuser --no-createdb --no-createrole --encrypted $PROJECT
	createdb --username=$POSTGRESQL_USERNAME --encoding=utf-8 --template=template0 --owner=$PROJECT $PROJECT
	psql --username=$POSTGRESQL_USERNAME --dbname=postgres --command="ALTER USER \"$PROJECT\" WITH ENCRYPTED PASSWORD '$PASSWORD'"
    fi

    # restart apache
    apachectl graceful

    if [ "$NGINX_ENABLED" != "NO" ]; then
	killall -1 nginx
    fi

    echo "project created"
    exit 0
fi

if [ "$ACTION" = "remove" ]; then
    echo "removing project '$PROJECT'"

    if [ ! -d "$REPOSITORIES_PATH/$PROJECT" -o ! -f "$APACHE_VIRTUALHOSTS_PATH/$PROJECT.$DEV_HOSTNAME.conf" -o ! -f "$APACHE_VIRTUALHOSTS_PATH/$PROJECT.$REL_HOSTNAME.conf" -o ! -d "$WWW_PATH/$PROJECT" ]; then
	echo "some of components doesn't exists but i'll remove it forcibly"
    fi

    # remove project's directories and configuration files
    rm -r $REPOSITORIES_PATH/$PROJECT
    rm $APACHE_VIRTUALHOSTS_PATH/$PROJECT.$DEV_HOSTNAME.conf
    rm $APACHE_VIRTUALHOSTS_PATH/$PROJECT.$REL_HOSTNAME.conf

    if [ -f "$CROND_PATH/$PROJECT" ]; then
	rm $CROND_PATH/$PROJECT
    fi

    if [ "$NGINX_ENABLED" != "NO" ]; then
	rm $NGINX_VIRTUALHOSTS_PATH/$PROJECT.$DEV_HOSTNAME.conf
	rm $NGINX_VIRTUALHOSTS_PATH/$PROJECT.$REL_HOSTNAME.conf
    fi

    rm -r $WWW_PATH/$PROJECT > /dev/null 2>&1

    # remove mysql username and database
    if [ "$MYSQL_ENABLED" != "NO" ]; then
cat << EOF | mysql -u$MYSQL_USERNAME -p$MYSQL_PASSWORD
DROP USER '$PROJECT'@'localhost';
DROP USER '$PROJECT'@'%';
DROP DATABASE IF EXISTS \`$PROJECT\`;
EOF
    fi

    # remove postgresql username and database
    if [ "$POSTGRESQL_ENABLED" != "NO" ]; then
	dropdb --username=$POSTGRESQL_USERNAME $PROJECT
	dropuser --username=$POSTGRESQL_USERNAME $PROJECT
    fi

    # restart apache
    apachectl graceful

    if [ "$NGINX_ENABLED" != "NO" ]; then
	killall -1 nginx
    fi

    echo "project removed"
    exit 0
fi

exit 1
