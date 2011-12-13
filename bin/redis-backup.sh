#!/bin/bash
#  November 1 2011
#  Backs up mongodatabases directory
#
# 0 3 * * * root /opt/mongo_backup/bin/mongo_backup.sh >> /var/log/mongodb.log
#

DAY=`date "+%d.%m.%Y"`
###куда бэкапить
BKDIR="/var/backups/redis"
###название директории
#MONGOBKCUR="${DAY}."
###путь до работающей БД
DBPATH="/var/lib/redis"



#
# Validate of directory exists or not before creating it
#

function dobackup { 
	echo; echo "::: ${DAY} - Starting"; echo;
	`/usr/bin/redis-cli bgsave >> /dev/null`
	`sleep 5`
	`cp $DBPATH/dump.rdb $BACKUPDIR/$DAY-redis.rdb`
}

if [ ! -f "/root/.redis" ];then
	exit;
fi

if [ $1 ];then
	if [ -d "$1" ];then
		BACKUPDIR=$1;
	else
		echo "Nu such directory!"
		exit
	fi
else
	BACKUPDIR="${BKDIR}/";
		
	if [ ! -d "$BACKUPDIR" ]; then
       		mkdir -p $BACKUPDIR;
	fi
fi
#
# Validate directory exists before dumping to it.  Prevent snowballs.
#

if [ -d "$BACKUPDIR" ]; then

	if [ `ps ax | grep "[r]edis-server" | wc -l` -ne 1 ]; then
	#daemon down
		echo "- Alert ::: Server down!";
	else
	##daemon up
		dobackup
	fi
else
	echo "  - Failure ::: Unable to create $BACKUPDIR/";
fi


echo "::: ${DAY} Concluded."; echo;

