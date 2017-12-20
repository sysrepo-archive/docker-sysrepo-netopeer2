# Install script for r2va-node-lwaftr-xenial

YANG="snabb-softwire-v2"

#install scapy for health check

easy_install pip
pip install exabgp
pip install ipaddr
pip install scapy


# Adding netconf user ####################################################
useradd -m netconf
mkdir -p /home/netconf/.ssh
echo "netconf:netconf" | chpasswd && adduser netconf

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
git checkout 2698bd6484526facbf82b1263810b938b82a2f23 && \
cmake -DCMAKE_BUILD_TYPE:String="Release" -DENABLE_BUILD_TESTS=OFF .. && \
make -j2 && \
make install && \
ldconfig


# sysrepo ########################################
cp -R /var/lib/vmfactory/files/sysrepo /opt/dev
cd /opt/dev/sysrepo && \
git fetch origin && \
git rebase origin/master && \
git checkout 8a188c515ad113adbe0d393fe54dc0cad2d0167a && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE:String="Release" -DENABLE_TESTS=OFF -DREPOSITORY_LOC:PATH=/etc/sysrepo -DGEN_LANGUAGE_BINDINGS=OFF -DENABLE_NACM=OFF  .. && \
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
git checkout bd93b091d6e4414283c6c764dc451aee61e09997 && \
cmake -DCMAKE_BUILD_TYPE:String="Release" -DENABLE_BUILD_TESTS=OFF .. && \
make -j2 && \
make install && \
ldconfig

# keystore ###############################
cp -R /var/lib/vmfactory/files/Netopeer2 /opt/dev
cd /opt/dev/Netopeer2 && \
git fetch origin && \
git rebase origin/master && \
git checkout ae560bef2e70d274f6d028b59e3cb398ea2a621d && \
cd keystored && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE:String="Release" .. && \
make -j2 && \
make install

# netopeer2 server
cd /opt/dev/Netopeer2/server && \
git checkout ae560bef2e70d274f6d028b59e3cb398ea2a621d && \
sed -i '/\<address\>/ s/0.0.0.0/\:\:/' ./stock_config.xml && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE:String="Release" .. && \
make -j2 && \
make install && \
ldconfig

# netopeer2 cli
cd /opt/dev/Netopeer2/cli && \
git checkout ae560bef2e70d274f6d028b59e3cb398ea2a621d && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE:String="Release" .. && \
make -j2 && \
make install && \
ldconfig

####################################### compile Igalia AFTR
cd /var/lib/vmfactory/files/snabb && \
git fetch origin && \
if [ "$YANG" == "snabb-softwire-v1" ]; then
	git checkout v3.1.9
elif [ "$YANG" == "snabb-softwire-v2" ]; then
	git checkout v2017.08.02
elif [ "$YANG" == "ietf-softwire" ]; then
	git rebase origin/lwaftr
fi && \
make -j2 && \
make install && \
mkdir -p /opt/snabb && \
cp -r /var/lib/vmfactory/files/snabb /opt

###########################################

# sysrepo-snabb-plugin
cp -R /var/lib/vmfactory/files/sysrepo-snabb-plugin /opt/dev
cd /opt/dev/sysrepo-snabb-plugin && \
git fetch origin && \
git rebase origin/master && \
git checkout d4bf1401289963f027fbb8d694bc07bb0588d7ab && \
mkdir build && cd build && \
{
	if [ "$YANG" == "snabb-softwire-v1" ]; then
		cmake -DPLUGIN=true -DYANG_MODEL="$YANG" -DLEAF_LIST=1 ..
	elif [ "$YANG" == "snabb-softwire-v2" ]; then
		cmake -DPLUGIN=true -DYANG_MODEL="$YANG" -DLEAF_LIST=0 ..
	elif [ "$YANG" == "ietf-softwire" ]; then
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
fi

echo "export PATH=\$PATH:/opt/scripts" >> /root/.bashrc

touch /var/log/exabgp.log
chown dtadmin:dtadmin /var/log/exabgp.log
touch /var/log/exabgphealthcheck.log
chown dtadmin:dtadmin /var/log/exabgphealthcheck.log

systemctl enable sysrepod.service
systemctl enable sysrepo-plugind.service
systemctl enable netopeer2-server.service
systemctl enable lwaftr.service
systemctl enable exabgp.service
