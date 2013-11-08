#! /usr/bin/env python
# -*- coding:utf-8

import os,sys,memcache,subprocess,time


#==============================================================================
# 当memcache进行flush_all后，从机向主机写入数据会有1秒左右的延迟
#==============================================================================

MEMCACHE_PID = "/var/run/memcached.pid"
REPLLOG = "/var/log/memcache_repl.log"
class Servers:
    def __init__(self):
        pass
        
    def set_serverstatus(self,address,servername,status):
        self.servername = servername
        self.status = status
        self.address = address
        conn = memcache.Client([address])
        conn.set(servername,status)
        conn.disconnect_all()
        
    
    def get_serverstatus(self,address,servername):
        self.servername = servername
        self.address = address
        conn = memcache.Client([address])
        server_info = conn.get(servername)
        conn.disconnect_all()        
        return server_info
        
    def clean_all(self,address):
        self.address = address
        conn = memcache.Client([address])
        conn.flush_all()
        conn.disconnect_all()
       


def memcached_pid_check(MEMCACHE_PID):
    if not (os.path.exists(MEMCACHE_PID)):
        os.system("/etc/init.d/memcached start")
    else:
        local_status = "OK"
    return local_status
        

def memcached_replication_check(master_address,slave_address,master_servername,slave_servername,master_status,slave_status):
    master = Servers()
    slave  = Servers()
    master.set_serverstatus(master_address,master_servername,master_status)
    slave.set_serverstatus(slave_address,slave_servername,slave_status)    
#==============================================================================
#     通过交叉读取服务器内容来进行内容的判断，从而认定服务器死活，
#从会从主机读自己的键值，主机也会从从机读取自己的键值    例如master从slave上
#get master的键值
#==============================================================================
        
    master_repl_key = slave.get_serverstatus(slave_address,master_servername)
    slave_repl_key =  master.get_serverstatus(master_address,slave_servername)
    
    if master_repl_key != master_status or slave_repl_key != slave_status:
        write_log = open(REPLLOG,'a')
        write_log.write("[%s] : memcached replication has disconnect!\n" %time.ctime())
        write_log.close()
        replstat = "disconnect"
    else:
        replstat = "replication"
    return replstat
        
memcached_replication_check("changemaster","changeslave","master","slave","master_alive","slave_alive")        


memcached_pid_check(MEMCACHE_PID)
time.sleep(3)
repl_status = memcached_replication_check("changemaster","changeslave","master","slave","master_alive","slave_alive")        
if repl_status != "replication":
    master_status = Servers()
    master_status.set_serverstatus("changemaster","master","master_alive")
    master_status_info = master_status.get_serverstatus("changemaster","master")
    time.sleep(1)
    if master_status_info == "master_alive":
        os.system("/etc/init.d/memcached restart")
        write_log = open(REPLLOG,'a')
        write_log.write("[%s] : memcached replication has reconnect!\n" %time.ctime())
        write_log.close()
        
    
    
