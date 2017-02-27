FROM ubuntu:16.04

MAINTAINER mislav.novakovic@sartura.hr

RUN \
      apt-get update && \
      apt-get install -y \
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

# libyang
RUN \
      cd /opt/dev && \
      git clone https://github.com/CESNET/libyang.git && \
      cd libyang && mkdir build && cd build && \
	  git checkout devel && \
      git checkout e3d871efaecb237aa6ed34726a7161a6e7c83f1e && \
      cmake -DCMAKE_BUILD_TYPE:String="Release" -DENABLE_BUILD_TESTS=OFF .. && \
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
       -DCMAKE_BUILD_TYPE:String="Release" \
      -DENABLE_TESTS=OFF \
      -DREPOSITORY_LOC:PATH=/etc/sysrepo \
      -DGEN_LUA_VERSION=5.1 \
      -DGEN_PYTHON_BINDINGS=false \
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
      cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug .. && \
      make -j2 && \
      make install

# libnetconf2
RUN \
      cd /opt/dev && \
      git clone https://github.com/CESNET/libnetconf2.git && \
      cd libnetconf2 && mkdir build && cd build && \
	  git checkout devel && \
      cmake -DCMAKE_BUILD_TYPE:String="Release" -DENABLE_BUILD_TESTS=OFF .. && \
      make -j2 && \
      make install && \
      ldconfig

# keystore
RUN \
      cd /opt/dev && \
      git clone https://github.com/CESNET/Netopeer2.git && \
	  cd Netopeer2 && git checkout devel-server && \
      cd keystored && mkdir build && cd build && \
      cmake -DCMAKE_BUILD_TYPE:String="Release" .. && \
      make -j2 && \
      make install

# netopeer2 server
RUN \
      cd /opt/dev && \
      cd Netopeer2/server && \
	  git checkout devel-server && \
      git checkout f005c89131949ee78f100d3eb86e6593797bd92c && \
      sed -i '/nc_server_endpt_set_address/ s/0.0.0.0/\:\:/' ./main.c && \
      mkdir build && cd build && \
      cmake -DCMAKE_BUILD_TYPE:String="Release" .. && \
      make -j2 && \
      make install && \
      ldconfig

# not necessary
# netopeer2 server
RUN \
      cd /opt/dev && \
      cd Netopeer2/cli && mkdir build && cd build && \
      git checkout ../../server/main.c && \
	  git checkout devel-cli && \
      cmake -DCMAKE_BUILD_TYPE:String="Release" .. && \
      make -j2 && \
      make install && \
      ldconfig

ENV EDITOR vim
EXPOSE 830
