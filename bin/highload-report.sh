#!/bin/sh

PATH="/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin"

STAMP=`date +%H%M%S`

echo "load average:" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
uptime >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp

if [ -f "/root/.mysql" ]; then
    echo "mysql:" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    mysql -u root -p`cat /root/.mysql` -e "SHOW FULL PROCESSLIST" | /bin/sort -n -k 6 >> /tmp/$STAMP.tmp 2>&1
    mysql -u root -p`cat /root/.mysql` -e "SHOW STATUS where value !=0" >> /tmp/$STAMP.tmp 2>&1
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

    echo "SELECT datname,procpid,current_query FROM pg_stat_activity;" | psql -U postgres --port=$PORT >> /tmp/$STAMP.tmp 2>&1
    echo >> /tmp/$STAMP.tmp
fi

echo "process list:" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
ps auwwwx >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp

echo "top list:" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
top -n 1 >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp

echo "top15 memory process list:" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
ps auwwwx | awk '{print $5/1000 "mb " $11}' | sort -g | tail -15 >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp

echo "SYN TCP/UDP Session:" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
netstat -n | egrep '(tcp|udp)' | grep SYN | wc -l >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp

echo "connections report:" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
netstat -plan | grep :80 | awk {'print $5'} | cut -d: -f 1 | sort | uniq -c | sort -n >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp

LINKSVER=`links -version | grep "2.2" | wc -l`
if [ $LINKSVER -gt 0 ]; then
    echo "apache:" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    links -dump -retries 1 -receive-timeout 30 http://localhost:8080/apache-status >> /tmp/$STAMP.tmp 2>&1
    echo >> /tmp/$STAMP.tmp

    echo "nginx:" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    links -dump -retries 1 -receive-timeout 30 http://localhost/nginx-status >> /tmp/$STAMP.tmp 2>&1
    echo >> /tmp/$STAMP.tmp
else
    echo "apache:" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    links -dump -eval 'set connection.retries = 1' -eval 'set connection.receive_timeout = 30' http://localhost:8080/apache-status >> /tmp/$STAMP.tmp 2>&1
    echo >> /tmp/$STAMP.tmp

    echo "nginx:" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    links -dump -eval 'set connection.retries = 1' -eval 'set connection.receive_timeout = 30' http://localhost/nginx-status >> /tmp/$STAMP.tmp 2>&1
    echo >> /tmp/$STAMP.tmp
fi

cat /tmp/$STAMP.tmp | mail -s "`hostname` load" root
rm /tmp/$STAMP.tmp

if [ "$1" = "apache-start" ]; then
    /etc/init.d/httpd start
fi

if [ "$1" = "apache-stop" ]; then
    killall -9 httpd
fi

if [ "$1" = "force-restart" ]; then
    killall -9 httpd
    sleep 2
    /etc/init.d/httpd start
fi

exit 1
