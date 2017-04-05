FROM ubuntu:16.04

MAINTAINER mislav.novakovic@sartura.hr

RUN \
      apt-get update && apt-get install -y \
      # general tools
      git \
      cmake \
      build-essential \
      vim \
      # libyang
      libpcre3-dev \
      # sysrepo
      libavl-dev \
      libev-dev \
      libprotobuf-c-dev \
      protobuf-c-compiler \
      # netopeer2 \
      libssl-dev \
      # bindings
      swig \
      lua5.1 \
      lua5.1-dev

# add netconf user
RUN \
    adduser --system netconf && \
    echo "netconf:netconf" | chpasswd

# add password to root user
RUN \
    echo "root:root" | chpasswd

# generate ssh keys for netconf user
RUN \
    mkdir -p /home/netconf/.ssh && \
    ssh-keygen -A && \
    ssh-keygen -t dsa -P '' -f /home/netconf/.ssh/id_dsa && \
    cat /home/netconf/.ssh/id_dsa.pub > /home/netconf/.ssh/authorized_keys

# create /opt/dev directory
RUN \
      mkdir /opt/dev -p

RUN echo "version 20170404"

# libyang
RUN \
      cd /opt/dev && \
      git clone https://github.com/CESNET/libyang.git && \
      cd libyang && mkdir build && cd build && \
      git checkout devel && \
      cmake \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE:String="Release" \
      -DENABLE_BUILD_TESTS=OFF .. && \
      make -j2 && \
      make install && \
      ldconfig

# sysrepo
RUN \
      cd /opt/dev && \
      git clone https://github.com/sysrepo/sysrepo.git && \
      cd sysrepo && \
      git checkout devel && \
      mkdir build && cd build && \
      cmake \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE:String="Release" \
      -DENABLE_TESTS=OFF \
      -DREPOSITORY_LOC:PATH=/etc/sysrepo \
      -DGEN_LUA_VERSION=5.1 \
      -DGEN_PYTHON_BINDINGS=false \
      -DENABLE_NACM=OFF \
      -DWITH_SYSTEMD=true \
      .. && \
      make -j2 && \
      make install && \
      ldconfig

# libssh-dev
RUN \
      apt-get install -y wget && \
      wget https://red.libssh.org/attachments/download/195/libssh-0.7.3.tar.xz && \
      tar xvfJ  libssh-0.7.3.tar.xz && \
      cd libssh-0.7.3 && \
      mkdir build && cd build && \
      cmake \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=Debug .. && \
      make -j2 && \
      make install

# libnetconf2
RUN \
      cd /opt/dev && \
      git clone https://github.com/CESNET/libnetconf2.git && \
      cd libnetconf2 && mkdir build && cd build && \
      git checkout devel && \
      cmake \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE:String="Release" \
      -DENABLE_BUILD_TESTS=OFF .. && \
      make -j2 && \
      make install && \
      ldconfig

# keystore
RUN \
      cd /opt/dev && \
      git clone https://github.com/CESNET/Netopeer2.git && \
      cd Netopeer2 && git checkout devel-server && \
      cd keystored && mkdir build && cd build && \
      cmake \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE:String="Release" .. && \
      make -j2 && \
      make install

# netopeer2 server
RUN \
      cd /opt/dev && \
      cd Netopeer2/server && \
      git checkout devel-server && \
      sed -i '/\<address\>/ s/0.0.0.0/\:\:/' ./stock_config.xml  && \
      cat ./stock_config.xml && \
      mkdir build && cd build && \
      cmake \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE:String="Release" .. && \
      make -j2 && \
      make install && \
      ldconfig

# add systemd service for netopeer2 server
COPY \
      netopeer2-serverd.service /lib/systemd/system

# not necessary
# netopeer2 server
RUN \
      cd /opt/dev && \
      cd Netopeer2/cli && mkdir build && cd build && \
      git checkout ../../server/stock_config.xml && \
      git checkout devel-cli && \
      cmake \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE:String="Release" .. && \
      make -j2 && \
      make install && \
      ldconfig

ENV EDITOR vim

# setup systemd

ENV \
      container docker
RUN \
      apt-get update && apt-get install -y systemd apt-utils && \
      (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done) && \
      rm -f /lib/systemd/system/multi-user.target.wants/* && \
      rm -f /etc/systemd/system/*.wants/* && \
      rm -f /lib/systemd/system/local-fs.target.wants/* && \
      rm -f /lib/systemd/system/sockets.target.wants/*udev* && \
      rm -f /lib/systemd/system/sockets.target.wants/*initctl* && \
      rm -f /lib/systemd/system/basic.target.wants/* && \
      rm -f /lib/systemd/system/anaconda.target.wants/*

# enable systemd services
RUN \
      systemctl enable sysrepod && \
      systemctl enable sysrepo-plugind && \
      systemctl enable netopeer2-serverd

VOLUME [ “/sys/fs/cgroup” ]

CMD [“/sbin/init”]

# docker run command
# sudo docker run -d -v /sys/fs/cgroup:/sys/fs/cgroup:ro --cap-add SYS_ADMIN -p 830:830 --name sysrepo --rm --privileged --entrypoint=/sbin/init sysrepo/sysrepo-netopeer2:snabb_devel

EXPOSE 830
