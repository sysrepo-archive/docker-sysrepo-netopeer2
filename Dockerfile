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
	  pkg-config \
	  bison \
	  flex \
      # sysrepo
      libavl-dev \
      libev-dev \
      libprotobuf-c-dev \
      protobuf-c-compiler \
      # netopeer2 \
      libssl-dev

RUN \
      apt-get update && apt-get install -y \
      python-pip

# creaet dir
RUN \
      mkdir -p /var/lib/vmfactory/files

COPY \
      ./systemd/* /lib/systemd/system/

# copy git repositories
RUN \
      cd /var/lib/vmfactory/files && \
      git clone https://github.com/CESNET/libyang.git && \
      git clone https://github.com/sysrepo/sysrepo.git && \
      git clone https://github.com/CESNET/libnetconf2.git && \
      git clone https://github.com/CESNET/Netopeer2.git && \
      git clone https://github.com/Igalia/snabb.git && \
	  git clone https://github.com/sysrepo/sysrepo-snabb-plugin.git

# wget libssh
RUN \
      apt-get install -y wget && \
      mkdir -p /var/lib/vmfactory/files/red.libssh.org/attachments/download/195 && \
      cd /var/lib/vmfactory/files/red.libssh.org/attachments/download/195 && \
	  echo "skip"#wget https://red.libssh.org/attachments/download/195/libssh-0.7.4.tar.xz

COPY libssh-0.7.4.tar.xz /var/lib/vmfactory/files/red.libssh.org/attachments/download/195

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

VOLUME [ “/sys/fs/cgroup” ]
CMD [“/sbin/init”]
ENV EDITOR vim

# docker run command
# sudo docker run -d -v /sys/fs/cgroup:/sys/fs/cgroup:ro --cap-add SYS_ADMIN -p 830:830 --name sysrepo --rm --privileged --entrypoint=/sbin/init sysrepo/sysrepo-netopeer2:snabb_devel

EXPOSE 830

# run the install script
RUN \
      mkdir /opt/scripts

COPY \
      ./install.sh /opt/scripts

RUN \
      bash /opt/scripts/install.sh

RUN \
      mkdir -p /opt/snabb/conf

COPY \
      ./scripts/lwaftrsysrepolua.sh /opt/snabb/conf

COPY \
      ./scripts/lwaftr.sh /opt/snabb/conf

RUN \
      systemctl disable exabgp.service
