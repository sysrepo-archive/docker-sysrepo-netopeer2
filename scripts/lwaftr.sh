#!/bin/bash

SNABBPATH=/opt/snabb/src
SNABBCONFPATH=/opt/snabb/conf

##### Set CPU Frequency
for CPUFREQ in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
   [ -f $CPUFREQ ] || continue;
   echo -n performance > $CPUFREQ;
done

$SNABBPATH/snabb lwaftr bench -b /dev/stdout --reconfigurable $SNABBPATH/program/lwaftr/tests/data/icmp_on_fail.conf $SNABBPATH/program/lwaftr/tests/benchdata/ipv{4,6}-0550.pcap
#sudo $SNABBPATH/snabb lwaftr run --cpu 12 --ring-buffer-size 1024 \
# --conf $SNABBCONFPATH/lwaftrhconly.conf --reconfigurable \
# --on-a-stick 0000:27:00.1 | tee /var/log/snabb.log
