# Install script for r2va-node-lwaftr-xenial

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
git checkout 4020635448634180485397acbefab00add8dab39 && \
cmake -DCMAKE_BUILD_TYPE:String="Release" -DENABLE_BUILD_TESTS=OFF .. && \
make -j2 && \
make install && \
ldconfig


# sysrepo ########################################
cp -R /var/lib/vmfactory/files/sysrepo /opt/dev
cd /opt/dev/sysrepo && \
git fetch origin && \
git rebase origin/master && \
git checkout 7aa2f18d234267403147df92c0005c871f0aa840 && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE:String="Release" -DENABLE_TESTS=OFF -DREPOSITORY_LOC:PATH=/etc/sysrepo -DGEN_LUA_VERSION=5.1 -DGEN_PYTHON_BINDINGS=false -DENABLE_NACM=OFF .. && \
make -j2 && \
make install && \
ldconfig


# libssh-dev ####################################
cp -R /var/lib/vmfactory/files/red.libssh.org/attachments/download/195/libssh-0.7.3.tar.xz /opt/dev
cd /opt/dev && \
tar xvfJ libssh-0.7.3.tar.xz && \
cd libssh-0.7.3 && \
mkdir build && cd build && \
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug .. && \
make -j2 && \
make install


# libnetconfd2 ###################################

cp -R /var/lib/vmfactory/files/libnetconf2 /opt/dev
cd /opt/dev/libnetconf2 && \
mkdir build && cd build && \
git fetch origin && \
git rebase origin/master && \
git checkout cea46db1edb72231c9e009d7e6d6799256676eb8 && \
cmake -DCMAKE_BUILD_TYPE:String="Release" -DENABLE_BUILD_TESTS=OFF .. && \
make -j2 && \
make install && \
ldconfig

# keystore ###############################
cp -R /var/lib/vmfactory/files/Netopeer2 /opt/dev
cd /opt/dev/Netopeer2 && \
git fetch origin && \
git rebase origin/master && \
git checkout 26474eda98665ddb46f72ac8ed72a14e9ac7bdb6 && \
cd keystored && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE:String="Release" .. && \
make -j2 && \
make install

# netopeer2 server
cd /opt/dev/Netopeer2/server && \
git fetch origin && \
git rebase origin/master && \
git checkout 26474eda98665ddb46f72ac8ed72a14e9ac7bdb6 && \
git remote add sartura https://github.com/sartura/Netopeer2.git && \
git fetch sartura && \
git checkout iter_fix_master && \
sed -i '/\<address\>/ s/0.0.0.0/\:\:/' ./stock_config.xml && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE:String="Release" .. && \
make -j2 && \
make install && \
sysrepoctl -d tls-listen -m ietf-netconf-server && \
sysrepoctl -d tls-call-home -m ietf-netconf-server && \
sysrepoctl -d ssh-call-home -m ietf-netconf-server && \
sysrepoctl -d call-home -m ietf-netconf-server && \
ldconfig

# netopeer2 cli
cd /opt/dev/Netopeer2/cli && \
git fetch origin && \
git rebase origin/master && \
git checkout 26474eda98665ddb46f72ac8ed72a14e9ac7bdb6 && \
mkdir build && cd build && \
cmake -DCMAKE_BUILD_TYPE:String="Release" .. && \
make -j2 && \
make install && \
ldconfig

####################################### compile Igalia AFTR
cd /var/lib/vmfactory/files/snabb && \
git fetch origin && \
git checkout release-v2017.07.01 && \
make -j2 && \
make install && \
mkdir -p /opt/snabb && \
cp -r /var/lib/vmfactory/files/snabb/* /opt/snabb

###########################################

# sysrepo-snabb-plugin
cp -R /var/lib/vmfactory/files/sysrepo-snabb-plugin /opt/dev
cd /opt/dev/sysrepo-snabb-plugin && \
git fetch origin && \
git rebase origin/master && \
mkdir build && cd build && \
cmake -DPLUGIN=true -DYANG_MODEL=snabb-softwire-v2 .. && \
make -j2 && \
make install

## copying/installing yang model from snabb to sysrepo
#sysrepoctl --install --yang=/opt/snabb/src/lib/yang/snabb-softwire-v1.yang
sysrepoctl --install --yang=/opt/snabb/src/lib/yang/snabb-softwire-v2.yang

#update-rc.d lwaftr defaults 80
#update-rc.d netconf defaults 10
#update-rc.d netconflua defaults 99
#update-rc.d exabgp defaults 99
#update-rc.d lwaftrcontrol defaults 80

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
