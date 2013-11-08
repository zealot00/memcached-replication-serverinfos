#! /bin/bash

service memcached stop

cd ./memcached-1.2.8-repcached-2.2.1/ && make uninstall >/dev/null 2>&1
cd - >/dev/null
rm -rf /etc/init.d/memcached
rm -rf /usr/bin/memcached

crontab -l 2>/dev/null >.crontab.tmp
sed -i "s/\* \* \* \* \* python \/usr\/local\/bin\/memcached_alive\.py//g" .crontab.tmp
crontab .crontab.tmp
rm -rf .crontab.tmp
if [ $? == 0 ];then
    echo "memcache_replication remove done!"
fi
