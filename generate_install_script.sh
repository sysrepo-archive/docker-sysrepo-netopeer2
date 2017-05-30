# copy temalpte
cp ./install.sh.in ./install.sh

# fetch latest git commit for libyang
COMMIT=$(git ls-remote https://github.com/CESNET/libyang.git --heads master | cut -f1)
sed -i "s/libyang_master_commit/${COMMIT}/" ./install.sh

# fetch latest git commit sysrepo
COMMIT=$(git ls-remote https://github.com/sysrepo/sysrepo.git --heads master | cut -f1)
sed -i "s/sysrepo_master_commit/${COMMIT}/" ./install.sh

# fetch latest git commit libnetconf2
COMMIT=$(git ls-remote https://github.com/CESNET/libnetconf2.git --heads master | cut -f1)
sed -i "s/libnetconf2_master_commit/${COMMIT}/" ./install.sh

# fetch latest git commit netopeer2
COMMIT=$(git ls-remote https://github.com/CESNET/Netopeer2.git --heads master | cut -f1)
sed -i "s/netopeer2_master_commit/${COMMIT}/" ./install.sh
