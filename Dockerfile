FROM fedora:latest
MAINTAINER Dave Baker <dbaker@redhat.com>



#--
# remove these once "yum update" requirements are settled.
# until then, these help speed up iterative builds by creating intermediate 
# layers with each successive set of packages known to be needed.
#RUN set -x && yum update -y
#RUN set -x && yum install -y libtool-ltdl libnsl libstdc++ ncurses npm cmake make curl gcc wget hostname findutils telnet git npm procps-ng net-tools gnupg
#RUN set -x && yum install -y gcc-c++ openssl-devel
#--


# - perform in few RUN statements to minimize intermediate images
RUN set -x && \
    ( if [ -e /etc/os-release ]; then cat /etc/os-release; fi ) && \
    yum -y update && \
    yum -y install --setopt=skip_missing_names_on_install=False    \
           libtool-ltdl libnsl libstdc++ libicu-devel ncurses npm  \
           gcc gcc-c++ openssl-devel cmake make curl wget hostname \
           findutils telnet git npm procps-ng net-tools gnupg      \
           perl-HTTP-Daemon-SSL rsync                           && \
    yum clean all && \
    rm -rf /var/cache/yum


# Args to fetch and compile znc
ENV GPG_KEY D5823CACB477191CAC0075555AE420CC0209989E
ENV ZNC_VERSION 1.7.4

ARG CMAKEFLAGS="-DCMAKE_INSTALL_PREFIX=/opt/znc -DWANT_CYRUS=NO -DWANT_PERL=NO -DWANT_PYTHON=NO -DWANT_IPV6=NO"
ARG MAKEFLAGS=""

RUN set -x && \
    # Download, verify signature, build and install ZNC \
    mkdir /src && cd /src && \
    curl -fsSL "https://znc.in/releases/archive/znc-${ZNC_VERSION}.tar.gz" -o znc.tgz && \
    curl -fsSL "https://znc.in/releases/archive/znc-${ZNC_VERSION}.tar.gz.sig" -o znc.tgz.sig && \
    # Oddly "docker build" and "buildah bud" both work with GNUPGHOME in /tmp, but "podman build" \
    # does not.  Putting the temp files in /dev/shm allows gpg-agent sockets to be created as needed \
    # and keeps gnupg operational. \
    export GNUPGHOME="$( mktemp -d --tmpdir=/dev/shm )" && \
    # recv-keys often fails, so retry up to four times to avoid failing the build \
    ( gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${GPG_KEY}" || \ 
      gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${GPG_KEY}" || \ 
      gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${GPG_KEY}" || \ 
      gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "${GPG_KEY}" ) && \
    gpg --batch --verify znc.tgz.sig znc.tgz && \
    # if gpg fails to verify, we abort the build here \
    rm -rf "$GNUPGHOME" && \
    tar -zxf znc.tgz --strip-components=1 && \
    mkdir build && cd build && \
    cmake .. ${CMAKEFLAGS} && \
    make $MAKEFLAGS && \
    make install && \
    cd / && rm -rf /src && \
    # Download and install irslackd \
    cd /opt && \
    git clone https://github.com/adsr/irslackd.git && \
    cd irslackd && \
    npm install && \
    # Prepare local dirs \
    mkdir /data

VOLUME /data


# Copy bootstrap code, probes, etc into container
COPY bin  /opt/bin/
COPY data /opt/data/


# Default znc port
EXPOSE 7776





# From here, we run as non-root.  Actual bootstrap config
# takes place inside the data volume after the first run so
# as to be preserved between restarts.
WORKDIR /data
CMD     /opt/bin/bootstrap.sh


