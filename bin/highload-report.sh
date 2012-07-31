#!/bin/sh

PATH="/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin"

STAMP=`date +%H%M%S`

echo "<html><body><pre>" >> /tmp/$STAMP.tmp
echo "<h3>load average</h3>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
uptime >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp

if [ -f "/root/.mysql" ]; then
    echo "<h3>mysql processes</h3>" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    mysql -u root -p`cat /root/.mysql` -e "SHOW FULL PROCESSLIST" | sort -n -k 6 >> /tmp/$STAMP.tmp 2>&1
    echo >> /tmp/$STAMP.tmp
fi

if [ -f "/root/.postgresql" ]; then
    echo "<h3>postgresql processes</h3>" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp

    if [ -f "/etc/init.d/pgbouncer" ]; then
        PORT="5454"
    else
        PORT="5432"
    fi

    echo "SELECT datname,procpid,current_query FROM pg_stat_activity;" | psql -U postgres --port=$PORT >> /tmp/$STAMP.tmp 2>&1
    echo >> /tmp/$STAMP.tmp
fi

echo "<h3>memory process list (top100)</h3>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
ps -ewwwo size,command --sort -size | head -100 | awk '{ hr=$1/1024 ; printf("%13.2f Mb ",hr) } { for ( x=2 ; x<=NF ; x++ ) { printf("%s ",$x) } print "" }' >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp

echo "<h3>process list (sort by cpu)</h3>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
ps -ewwwo pcpu,pid,user,command --sort -pcpu >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp

LINKSVER=`links -version | grep "2.2" | wc -l`
if [ $LINKSVER -gt 0 ]; then
    echo "<h3>apache</h3>" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    links -dump -retries 1 -receive-timeout 30 http://localhost:8080/apache-status >> /tmp/$STAMP.tmp 2>&1
    echo >> /tmp/$STAMP.tmp

    echo "<h3>nginx</h3>" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    links -dump -retries 1 -receive-timeout 30 http://localhost/nginx-status >> /tmp/$STAMP.tmp 2>&1
    echo >> /tmp/$STAMP.tmp
else
    echo "<h3>apache</h3>" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    links -dump -eval 'set connection.retries = 1' -eval 'set connection.receive_timeout = 30' http://localhost:8080/apache-status >> /tmp/$STAMP.tmp 2>&1
    echo >> /tmp/$STAMP.tmp

    echo "<h3>nginx</h3>" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    links -dump -eval 'set connection.retries = 1' -eval 'set connection.receive_timeout = 30' http://localhost/nginx-status >> /tmp/$STAMP.tmp 2>&1
    echo >> /tmp/$STAMP.tmp
fi

echo "<h3>connections report</h3>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
netstat -plan | grep :80 | awk {'print $5'} | cut -d: -f 1 | sort | uniq -c | sort -n >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp

echo "<h3>syn tcp/udp session</h3>" >> /tmp/$STAMP.tmp
echo >> /tmp/$STAMP.tmp
netstat -n | egrep '(tcp|udp)' | grep SYN | wc -l >> /tmp/$STAMP.tmp 2>&1
echo >> /tmp/$STAMP.tmp

if [ -f "/root/.mysql" ]; then
    echo "<h3>mysql status</h3>" >> /tmp/$STAMP.tmp
    echo >> /tmp/$STAMP.tmp
    mysql -u root -p`cat /root/.mysql` -e "SHOW STATUS where value !=0" >> /tmp/$STAMP.tmp 2>&1
    echo >> /tmp/$STAMP.tmp
fi

SUBJECT="`hostname` load"
echo "</pre></body></html>" >> /tmp/$STAMP.tmp

cat - /tmp/$STAMP.tmp <<EOF | sendmail -oi -t
To: root
Subject: $SUBJECT
Content-Type: text/html; charset=utf8
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0

EOF

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
