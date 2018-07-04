#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Install script for r2va-node-lwaftr-xenial

# Maximum number of children nodes (of any parent node) being fetched in one message from Sysrepo Engine when processing sr_get_subtree(s)_*_chunk(s). Increasing this can improve efficiency when working with large datastores at the cost of higher memory usage peaks.
SUBTREE_LIMIT=100
# Number of items being fetched in one message from Sysrepo Engine when processing sr_get_items_iter calls. Increasing this can improve efficiency when working with large datastores at the cost of higher memory usage peaks.
FETCH_LIMIT=1000000
# timeout in seconds for all timeouts
TIMEOUT=1200

YANG="snabb-softwire-v2"

#install scapy for health check

easy_install pip
pip install exabgp
pip install ipaddr
pip install scapy


# Adding netconf user ####################################################
useradd -m netconf
echo "netconf:netconf" | chpasswd
mkdir -p /home/netconf/.ssh

# Clearing and setting authorized ssh keys ##############################
echo '' > /home/netconf/.ssh/authorized_keys
ssh-keygen -A
ssh-keygen -t dsa -P '' -f /home/netconf/.ssh/id_dsa
cat /home/netconf/.ssh/id_dsa.pub >> /home/netconf/.ssh/authorized_keys

# Updating shell to bash ##################################################
sed -i s#/home/netconf:/bin/false#/home/netconf:/bin/bash# /etc/passwd
mkdir /opt/dev && chown -R netconf /opt/dev
# set root password to root#################################################
echo "root:root" | chpasswd

# create /opt/dev directory
mkdir /opt/dev -p

##### libyang ####################
echo "Install libyang"
cp -R /var/lib/vmfactory/files/libyang /opt/dev
cd /opt/dev/libyang && \
mkdir build && cd build && \
git fetch origin && \
git rebase origin/master && \
git checkout f77877617535c402cf0ae7c5b68407c48e40d0eb && \
cmake -DCMAKE_BUILD_TYPE:String="Release" -DENABLE_BUILD_TESTS=OFF .. && \
make -j2 && \
make install && \
ldconfig


# sysrepo ########################################
cp -R /var/lib/vmfactory/files/sysrepo /opt/dev
cd /opt/dev/sysrepo && \
git fetch origin && \
git rebase origin/master && \
git checkout 724a62fa830df7fcb2736b1ec41b320abe5064d2 && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE:String="Release" -DENABLE_TESTS=OFF -DREPOSITORY_LOC:PATH=/etc/sysrepo -DGEN_LANGUAGE_BINDINGS=OFF -DENABLE_NACM=OFF \
-DREQUEST_TIMEOUT="$TIMEOUT" -DCOMMIT_VERIFY_TIMEOUT="$TIMEOUT" -DOPER_DATA_PROVIDE_TIMEOUT="$TIMEOUT" -DNOTIF_TIME_WINDOW="$TIMEOUT" \
-DGET_ITEMS_FETCH_LIMIT="$FETCH_LIMIT" -DGET_SUBTREE_CHUNK_CHILD_LIMIT="$SUBTREE_LIMIT" \
.. && \
make -j2 && \
make install && \
ldconfig


# libssh-dev ####################################
cp -R /var/lib/vmfactory/files/red.libssh.org/attachments/download/195/libssh-0.7.3.tar.xz /opt/dev
cd /opt/dev && \
tar xvfJ libssh-0.7.3.tar.xz && \
cd libssh-0.7.3 && \
mkdir build && cd build && \
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE:String="Release" .. && \
make -j2 && \
make install


# libnetconfd2 ###################################
cp -R /var/lib/vmfactory/files/libnetconf2 /opt/dev
cd /opt/dev/libnetconf2 && \
mkdir build && cd build && \
git fetch origin && \
git rebase origin/master && \
git checkout f7033524cd8dde13c31cb6949948e022f294dc7d && \
cmake -DCMAKE_BUILD_TYPE:String="Release" -DENABLE_BUILD_TESTS=OFF \
-DREAD_INACTIVE_TIMEOUT="$TIMEOUT" -DREAD_ACTIVE_TIMEOUT="$TIMEOUT" \
.. && \
make -j2 && \
make install && \
ldconfig

# keystore ###############################
cp -R /var/lib/vmfactory/files/Netopeer2 /opt/dev
cd /opt/dev/Netopeer2 && \
git fetch origin && \
git rebase origin/master && \
git checkout b1a450f6bbebbd95f5ece431c77d6fec9d256fbb && \
cd keystored && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE:String="Release" .. && \
make -j2 && \
make install

# netopeer2 server
cd /opt/dev/Netopeer2/server && \
git checkout b1a450f6bbebbd95f5ece431c77d6fec9d256fbb && \
sed -i '/\<address\>/ s/0.0.0.0/\:\:/' ./stock_config.xml && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE:String="Release" .. && \
make -j2 && \
make install && \
ldconfig

# netopeer2 cli
cd /opt/dev/Netopeer2/cli && \
git checkout b1a450f6bbebbd95f5ece431c77d6fec9d256fbb && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE:String="Release" .. && \
make -j2 && \
make install && \
ldconfig

####################################### compile Igalia AFTR
cp -r /var/lib/vmfactory/files/snabb /opt
cd /opt/snabb
git fetch origin
if [ "$YANG" == "snabb-softwire-v1" ]; then
	git checkout v3.1.9
elif [ "$YANG" == "snabb-softwire-v2" ]; then
	git checkout lwaftr
elif [ "$YANG" == "ietf-softwire" ]; then
	git checkout lwaftr
elif [ "$YANG" == "ietf-softwire-br" ]; then
	git checkout lwaftr
fi
echo "build snabb"
cd /opt/snabb && make -j2
cd /opt/snabb && make install

###########################################

# sysrepo-snabb-plugin
cp -R /var/lib/vmfactory/files/sysrepo-snabb-plugin /opt/dev
cd /opt/dev/sysrepo-snabb-plugin && \
git fetch origin && \
git rebase origin/master && \
git checkout 2cedae8685c2b73148144a8644f43ec8c7ec288c && \
mkdir build && cd build && \
{
	if [ "$YANG" == "snabb-softwire-v1" ]; then
		cmake -DPLUGIN=true -DYANG_MODEL="$YANG" -DLEAF_LIST=1 ..
	else
		cmake -DPLUGIN=true -DYANG_MODEL="$YANG" -DLEAF_LIST=0 ..
	fi
} && \
make -j2 && \
make install

if [ "$YANG" == "snabb-softwire-v1" ]; then
	sysrepoctl --install --yang=/opt/snabb/src/lib/yang/snabb-softwire-v1.yang
elif [ "$YANG" == "snabb-softwire-v2" ]; then
	sysrepoctl --install --yang=/opt/snabb/src/lib/yang/snabb-softwire-v2.yang
elif [ "$YANG" == "ietf-softwire" ]; then
	sysrepoctl --install --yang=/opt/snabb/src/lib/yang/ietf-softwire.yang
	sysrepoctl -e binding -m ietf-softwire
	sysrepoctl -e br -m ietf-softwire
elif [ "$YANG" == "ietf-softwire-br" ]; then
	sysrepoctl --install --yang=/opt/snabb/src/lib/yang/ietf-softwire-br.yang
	sysrepoctl --install --yang=/opt/snabb/src/lib/yang/ietf-softwire-common.yang
	sysrepoctl -e binding -m ietf-softwire-br
fi

echo "export PATH=\$PATH:/opt/scripts" >> /root/.bashrc

touch /var/log/exabgp.log
#chown dtadmin:dtadmin /var/log/exabgp.log
touch /var/log/exabgphealthcheck.log
#chown dtadmin:dtadmin /var/log/exabgphealthcheck.log

systemctl enable sysrepod.service
systemctl enable sysrepo-plugind.service
systemctl enable netopeer2-server.service
systemctl enable lwaftr.service
systemctl enable exabgp.service
