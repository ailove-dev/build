#!/bin/sh

PATH=/usr/bin:/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH

cd /srv/www
for PROJECT in *; do
    [[ -d "$PROJECT" ]] || continue

cat << EOF > /srv/www/$PROJECT/conf/nginx-dev.conf
server {
    listen 80;
    server_name $PROJECT.dev.ailove.ru;

    access_log /srv/www/$PROJECT/logs/$PROJECT.dev.ailove.ru-acc main;
    error_log /srv/www/$PROJECT/logs/$PROJECT.dev.ailove.ru-err;

    location / {
	proxy_pass http://127.0.0.1:8080;
	proxy_redirect off;
	proxy_set_header Host \$host;
	proxy_set_header X-Real-IP \$remote_addr;
	proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

	proxy_read_timeout 300;
	client_max_body_size 256m;

	proxy_buffer_size 16k;
	proxy_buffers 32 16k;
    }

    location ^~ /data/ {
	root /srv/www/$PROJECT;
    }

    include vhost.inc.conf;
}
EOF
ln -s /srv/www/$PROJECT/conf/nginx-dev.conf /etc/nginx/vhosts-svn.d/$PROJECT.dev.ailove.ru.conf

cat << EOF > /srv/www/$PROJECT/conf/nginx-rel.conf
server {
    listen 80;
    server_name $PROJECT.rel.ailove.ru;

    access_log /srv/www/$PROJECT/logs/$PROJECT.rel.ailove.ru-acc main;
    error_log /srv/www/$PROJECT/logs/$PROJECT.rel.ailove.ru-err;

    location / {
	proxy_pass http://127.0.0.1:8080;
	proxy_redirect off;
	proxy_set_header Host \$host;
	proxy_set_header X-Real-IP \$remote_addr;
	proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

	proxy_read_timeout 300;
	client_max_body_size 256m;

	proxy_buffer_size 16k;
	proxy_buffers 32 16k;
    }

    location ^~ /data/ {
	root /srv/www/$PROJECT;
    }

    include vhost.inc.conf;
}
EOF
ln -s /srv/www/$PROJECT/conf/nginx-rel.conf /etc/nginx/vhosts-svn.d/$PROJECT.rel.ailove.ru.conf

done

exit
cd /etc/httpd/vhosts-svn.d
for PROJECT in *; do
    [[ -f "$PROJECT" ]] || continue

    sed -i 's/*:80/*/g' $PROJECT

done

exit

cd /srv/www
for PROJECT in *; do
    [[ -d "$PROJECT" ]] || continue
    touch $PROJECT/conf/revision
    chown svn:svn $PROJECT/conf/revision
    chmod 644 $PROJECT/conf/revision
    echo "revision=`LANG=ru_RU.UTF-8 svnversion $PROJECT/repo/dev`" > $PROJECT/conf/revision
done

cd /srv/svn
for PROJECT in *; do
    [[ -d "$PROJECT" ]] || continue

    echo "#!/bin/sh" > $PROJECT/hooks/post-commit
    echo >> $PROJECT/hooks/post-commit
    echo "LANG=ru_RU.UTF-8 /usr/bin/sudo -u svn /usr/bin/svn --non-interactive update /srv/www/$PROJECT/repo" >> $PROJECT/hooks/post-commit
    echo "/usr/bin/sudo -u svn /srv/admin/bin/update-revision.sh $PROJECT" >> $PROJECT/hooks/post-commit
done

echo "this is a test script, don't use it!"
exit

function ini_load {
    # param1 inifile
    local tmpfile=`(mktemp "${TMPDIR-/tmp}/bash_inifileXXXXXXXX") 2>/dev/null || echo ${TMPDIR-/tmp}/bash_inifile$$`
    awk -v INI_PREFIX=${INI_PREFIX} -f - "$1" >$tmpfile <<EOF

# default global section
BEGIN {
  FS="[[:space:]]*=[[:space:]]*"
  section="globals";
}

{
 # kill comments 
 sub(/;.*/, "");
}

/^\[[^\]]+\]$/ {
 section=substr(\$0, 2, length(\$0) -2);
 # map section to valid shell variables
 gsub(/[^[[:alnum:]]/, "_", section)
 printf "%s%s_keys=()\n", INI_PREFIX, section, INI_PREFIX, section
 printf "%s%s_values=()\n", INI_PREFIX, section, INI_PREFIX, section
}

\$1 ~ /^[[:alnum:]\._]+\$/ {
 # remove trail/head single/double quotes
 gsub(/(^[\"\']|[\'\"]\$)/, "", \$2);
 # escape inside single quotes 
 gsub(/\47/, "'\"'\"'", \$2);
 printf "%s%s_keys=(\"\${%s%s_keys[@]}\" '%s')\n", INI_PREFIX, section, INI_PREFIX, section, \$1
 printf "%s%s_values=(\"\${%s%s_values[@]}\" '%s')\n", INI_PREFIX, section, INI_PREFIX, section, \$2
}
EOF

while read line ; do
    eval $line
done  <${tmpfile}

rm ${tmpfile}

}

function ini_get_value {
    # param1 section
    # param2 key
    
    # map section to valid bash variable like in awk parsing
    local section=${1//[![:alnum:]]/_}
    local keyarray=${INI_PREFIX}${section}_keys[@]
    local valuearray=${INI_PREFIX}${section}_values[@]
    local keys=("${!keyarray}")
    local values=("${!valuearray}")
    for (( i=0; i<${#keys[@]}; i++ )); do
	if [[ "${keys[$i]}" = "$2" ]]; then
	    echo "${values[$i]}"
	    return 0
	fi
    done
    return 1
}

MYSQL_USERNAME="root"
MYSQL_PASSWORD=`cat /root/.mysql`

#cd /srv/www
#for PROJECT in *; do
#    [[ -d "$PROJECT" ]] || continue

PROJECT=$1

    ini_load /srv/www/$PROJECT/conf/database
    PASSWORD=`ini_get_value globals DB_PASSWORD`

#echo $PROJECT
#echo $PASSWORD

cat << EOF | mysql -u$MYSQL_USERNAME -p$MYSQL_PASSWORD
GRANT USAGE ON *.* TO '$PROJECT'@'%' IDENTIFIED BY '$PASSWORD' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
GRANT ALL PRIVILEGES ON \`$PROJECT\`.* TO '$PROJECT'@'%';
EOF

#done

#cd /etc/httpd/vhosts-svn.d
#for PROJECT in *; do
#    [[ -f "$PROJECT" ]] || continue
#    cat /etc/httpd/vhosts-svn.d/$PROJECT | grep -v "/cache/" >/tmp/$PROJECT
#    cat /tmp/$PROJECT > /etc/httpd/vhosts-svn.d/$PROJECT
#    rm /tmp/$PROJECT
#done
#/etc/init.d/httpd restart
