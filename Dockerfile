FROM ubuntu:14.04

RUN \
      apt-get update && apt-get install -y \
      git \
      curl \
      wget \
      libssl-dev \
      libtool \
      build-essential \
      autoconf \
      automake \
      pkg-config \
      libgtk-3-dev \
      cmake \
      make \
      vim \
      valgrind \
      doxygen \
      libev-dev \
      libavl-dev \
      libpcre3-dev \
      unzip \
      sudo \
      python-setuptools \
      python-dev \
      build-essential \
      bison \
      flex \
      nodejs \
      npm

# pyang
RUN easy_install pip
RUN pip install --upgrade pyang

# Adding netconf user
RUN adduser --system netconf
RUN mkdir -p /home/netconf/.ssh
RUN echo "netconf:netconf" | chpasswd && adduser netconf sudo

# Clearing and setting authorized ssh keys
RUN echo '' > /home/netconf/.ssh/authorized_keys
RUN ssh-keygen -A
RUN ssh-keygen -t dsa -P '' -f /home/netconf/.ssh/id_dsa
RUN cat /home/netconf/.ssh/id_dsa.pub >> /home/netconf/.ssh/authorized_keys

# Updating shell to bash
RUN sed -i s#/home/netconf:/bin/false#/home/netconf:/bin/bash# /etc/passwd

RUN mkdir /opt/dev && sudo chown -R netconf /opt/dev

# swig
RUN \
      cd /opt/dev && \
      git clone https://github.com/swig/swig.git && cd swig && \
      ./autogen.sh && \
      ./configure --prefix=/usr && \
      make -j2 && \
      make install

#cmocka
RUN \
      cd /opt/dev && \
      git clone git://git.cryptomilk.org/projects/cmocka.git && cd cmocka && \
      git checkout tags/cmocka-1.0.1 && \
      mkdir build && cd build && \
      cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr .. && \
      make -j2 && \
      make install

# libssh
RUN \
      cd /opt/dev && \
      git clone http://git.libssh.org/projects/libssh.git && cd libssh && \
      mkdir build && cd build && \
      cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr .. && \
      make -j2 && \
      make install

# protobuf
RUN \
      cd /opt/dev && \
      git clone https://github.com/google/protobuf.git && cd protobuf && \
      ./autogen.sh && \
      ./configure --prefix=/usr && \
      make -j2 && \
      make install

# protobuf-c
RUN \
      cd /opt/dev && \
      git clone https://github.com/protobuf-c/protobuf-c.git && cd protobuf-c && \
      ./autogen.sh && \
      ./configure --prefix=/usr && \
      make -j2 && \
      make install

# libredblack
RUN \
      cd /opt/dev && \
      git clone https://github.com/sysrepo/libredblack.git && cd libredblack && \
      ./configure && \
      make -j2 && \
      make install

# libyang
RUN \
      cd /opt/dev && \
      git clone https://github.com/CESNET/libyang.git && cd libyang && \
      git checkout master && \
      mkdir build && cd build && \
      cmake -DCMAKE_BUILD_TYPE:String="Release" -DCMAKE_INSTALL_PREFIX:PATH=/usr -DENABLE_BUILD_TESTS=OFF .. && \
      make -j2 && \
      make install

# libnetconf2
RUN \
      cd /opt/dev && \
      git clone https://github.com/CESNET/libnetconf2.git && cd libnetconf2 && \
      git checkout master && \
      mkdir build && cd build && \
      cmake  -DCMAKE_BUILD_TYPE:String="Release" -DCMAKE_INSTALL_PREFIX:PATH=/usr -DENABLE_BUILD_TESTS=OFF .. && \
      make -j2 && \
      make install

# sysrepo
RUN \
      cd /opt/dev && \
      git clone https://github.com/sysrepo/sysrepo.git && cd sysrepo && \
      mkdir build && cd build && \
      cmake -DENABLE_TESTS=ON -DCMAKE_BUILD_TYPE="Release" -DCMAKE_INSTALL_PREFIX:PATH=/usr -DREPOSITORY_LOC:PATH=/etc/sysrepo .. && \
      make -j2 && \
      make install

# netopeer 2
RUN \
      cd /opt/dev && git clone https://github.com/CESNET/Netopeer2.git && cd Netopeer2 && \
      git checkout master && \
      cd /opt/dev/Netopeer2/server && \
      mkdir build && cd build \
      && cmake -DCMAKE_BUILD_TYPE:String="Release" -DCMAKE_INSTALL_PREFIX:PATH=/usr .. && \
      make -j2 && \
      make install && \
      cd /opt/dev/Netopeer2/cli && \
      mkdir build && cd build && \
      cmake -DCMAKE_BUILD_TYPE:String="Release" -DCMAKE_INSTALL_PREFIX:PATH=/usr .. && \
      make -j2 && \
      make install

RUN sysrepoctl --install --yang=/opt/dev/sysrepo/yang/turing-machine.yang

EXPOSE 6001
CMD ["/usr/bin/sysrepod"]
CMD ["/usr/bin/netopeer2-server", "-d"]
