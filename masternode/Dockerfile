FROM ubuntu:16.04

RUN apt-get update
RUN apt-get -y install build-essential libtool autotools-dev automake \
    pkg-config libssl-dev libevent-dev bsdmainutils libboost-system-dev \
    libboost-filesystem-dev libboost-chrono-dev \
    libboost-program-options-dev libboost-test-dev libboost-thread-dev \
    libminiupnpc-dev libgmp3-dev libdb-dev libdb++-dev libgmp3-dev git wget curl

RUN latestBaseurl="$(curl -s https://api.github.com/repos/tianon/gosu/releases \
    | grep browser_download_url | head -n 1 | cut -d '"' -f 4 | sed 's:/[^/]*$::')" \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && curl -o /usr/local/bin/gosu -SL "$latestBaseurl/gosu-$dpkgArch" \
    && curl -o /usr/local/bin/gosu.asc -SL "$latestBaseurl/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys \
    B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/pepeteam/pepecoin.git
RUN cd  pepecoin/src && make -f makefile.unix
RUN mkdir -p /usr/local/bin && cp pepecoin/src/pepecoind /usr/local/bin \
    && chmod 755 /usr/local/bin/pepecoind && rm -rf /pepecoin

# Default p2p communication port, 
# can be changed via $OPTS (e.g. docker run -e OPTS="-port=9876")
#Defaults are 29377

EXPOSE 29377

COPY entry.sh /usr/local/bin/entry.sh
RUN chmod 755 /usr/local/bin/entry.sh

ENTRYPOINT ["/usr/local/bin/entry.sh"]

CMD ["/usr/local/bin/pepecoind"]

