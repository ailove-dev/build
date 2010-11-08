#!/bin/sh

STAMP=`date +%H%M%S`

echo "load average:" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
/usr/bin/uptime >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp

if [ -d "/etc/httpd" ]; then
    echo "apache:" >> /tmp/$STAMP.tmp
    /usr/bin/links -dump http://localhost/apache-status >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
fi

if [ -d "/etc/nginx" ]; then
    echo "nginx:" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    /usr/bin/links -dump http://localhost/nginx-status >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
fi

if [ -f "/root/.mysql" ]; then
    echo "mysql:" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    /usr/bin/mysql -u root -p`cat /root/.mysql` -e "SHOW PROCESSLIST" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
fi

if [ -f "/root/.postgresql" ]; then
    echo "postgresql:" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp

    if [ -f "/etc/init.d/pgbouncer" ]; then
	PORT="5454"
    else
	PORT="5432"
    fi

    echo "SELECT datname,procpid,current_query FROM pg_stat_activity;" | /usr/bin/psql -U postgres --port=$PORT >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
fi

echo "process list:" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
ps awwwx >> /tmp/$STAMP.tmp

cat /tmp/$STAMP.tmp | mail -s "`hostname` load" root
rm /tmp/$STAMP.tmp
