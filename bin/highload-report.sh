#!/bin/sh

STAMP=`date +%H%M%S`

echo "load average:" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
/usr/bin/uptime >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp

echo "apache:" >> /tmp/$STAMP.tmp
/usr/bin/links -dump -eval 'set connection.receive_timeout = 60' -eval 'set connection.retries = 1' http://localhost:8080/apache-status >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp

echo "nginx:" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
/usr/bin/links -dump -eval 'set connection.receive_timeout = 60' -eval 'set connection.retries = 1' http://localhost/nginx-status >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp

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
ps auwwwx >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp

echo "top15 memory process list:" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
ps auwwwx | awk '{print $5/1000 "mb " $11}' | sort -g | tail -15 >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp

echo "connections report:" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
netstat -plan | grep :80 | awk {'print $5'} | cut -d: -f 1 | sort | uniq -c | sort -n >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp

cat /tmp/$STAMP.tmp | mail -s "`hostname` load" root
rm /tmp/$STAMP.tmp

if [ "$1" = "apache-start" ]; then
    /etc/init.d/httpd start
fi

if [ "$1" = "apache-stop" ]; then
    /usr/bin/killall -9 httpd
fi

if [ "$1" = "force-restart" ]; then
    /usr/bin/killall -9 httpd
    sleep 2
    /etc/init.d/httpd start
fi

exit 1
