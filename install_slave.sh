#! /bin/bash


LIBEVENT_PATH=/usr
REPLCACHE_PATH=/usr/local/memcached

#config file info
pidfile=/var/run/memcached.pid
echo "memcached running user:"
read memcacheduser
echo "memcached local address:"
read local_addr
echo "memcahced master address:"
read master_addr
echo "memcached local port: (default:11211)"
read local_port
echo "memcached replport: (default:11212)"
read repl_port

install_libevent() {
cd libevent-1.4.9-stable/
./configure --prefix=$LIBEVENT_PATH >/dev/null 2>&1  && make >/dev/null 2>&1  && make install >/dev/null 2>&1
libstat=$?
cd ..
if [ $libstat -eq 0 ];then
    echo "install libevent successed !"
    return 0
else
   echo "install libevent fail ! error code `echo $libevent` .."
   exit 1
fi 
}

install_memcached_replication() {
cd memcached-1.2.8-repcached-2.2.1/
./configure --prefix=$REPLCACHE_PATH --enable-replication --with-libevent=$LIBEVENT_PATH  >/dev/null 2>&1  && make >/dev/null 2>&1  && make install >/dev/null 2>&1
memcachedstat=$?
if [ $memcachedstat -eq 0 ];then
    ln -s /usr/local/memcached/bin/memcached /usr/bin/
    cd ..
    #echo "memcached -d -u $memcacheduser -l $local_addr -m 1024 -P $pidfile -p $local_port -x $master_addr -X $repl_port" >> /etc/rc.d/boot.local
    start_commond="memcached -d -u $memcacheduser -l $local_addr -m 1024 -P $pidfile -p $local_port -x $master_addr -X $repl_port"
    sed -i "/.*then.*/a\        $start_commond" memcached
    sed -i "/.*else.*/a\        $start_commond" memcached
    sed -i "s/changemaster/$master_addr:11211/g" ./lib/memcached_alive.py 
    sed -i "s/changeslave/$local_addr:11211/g" ./lib/memcached_alive.py 
    crontab -l 2>/dev/null | sed '/^#/d' >.crontab.tmp
    if ! grep -q "/usr/local/bin/memcached_alive.py" .crontab.tmp ;then
        echo "* * * * * python /usr/local/bin/memcached_alive.py" >> .crontab.tmp
    fi
    crontab .crontab.tmp
    rm -rf .crontab.tmp
    sed -i "20 i SERVER_INFO=slave" memcached
    install ./lib/memcache.py /usr/lib64/python2.6/site-packages/
    install ./lib/memcached_alive.py /usr/local/bin/
    chmod 755 /usr/local/bin/memcached_alive.py
    touch /var/log/memcache_repl.log
    install ./memcached /etc/init.d/
    chmod +x /etc/init.d/memcached
    chkconfig memcached on >/dev/null 2>&1

    memcached -d -u $memcacheduser -l $local_addr -m 1024 -P $pidfile -p $local_port -x $master_addr -X $repl_port

    echo "memcache_replicache slave install successed !"
fi
}

install_libevent 
install_memcached_replication 
