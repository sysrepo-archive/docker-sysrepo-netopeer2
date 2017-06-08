#!/bin/bash
sleep 30
echo -n -e "Starting Sysrepo Lua Bindings: \n"
AFTRPID=`pgrep -l snabb | awk '!/sup/ {print $1}'`
/usr/bin/lua /opt/snabb/sysrepo/sysrepo.lua snabb-softwire-v1 $AFTRPID
