FROM haydenkow/nu-dcdev:release-4.7.3-rc3 as dcdev
FROM gcc:7.4 as builder
MAINTAINER HaydenKow <hayden@hkowsoftware.com>
ENV DEBIAN_FRONTEND noninteractive

COPY --from=dcdev /opt/toolchains/dc /opt/toolchains/dc

# Fetch sources
WORKDIR /opt/toolchains/dc/kos
RUN mkdir -p /opt/toolchains/dc && \
	git -C /opt/toolchains/dc/kos pull origin master && \
        git -C /opt/toolchains/dc/kos-ports pull origin master && \
        cp /opt/toolchains/dc/kos/doc/environ.sh.sample /opt/toolchains/dc/kos/environ.sh && \
        sed -i 's/-fno-rtti//' /opt/toolchains/dc/kos/environ_base.sh && \
        sed -i 's/-fno-exceptions//' /opt/toolchains/dc/kos/environ_base.sh && \
        sed -i 's/-fno-operator-names//' /opt/toolchains/dc/kos/environ_base.sh && \
        sed -i 's/-fno-strict-aliasing//' /opt/toolchains/dc/kos/environ_base.sh && \
	bash -c 'source /opt/toolchains/dc/kos/environ.sh ; make clean && make && make kos-ports_all'

FROM debian:stretch
COPY --from=builder /opt/toolchains/dc /opt/toolchains/dc

RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-upgrade \
        cmake \
        make \
        git \
        wget \
    && echo "dash dash/sh boolean false" | debconf-set-selections \
    && dpkg-reconfigure --frontend=noninteractive dash \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && wget http://ftp.br.debian.org/debian/pool/main/n/ncurses/libncurses6_6.1+20190803-1_amd64.deb \
    && wget http://ftp.br.debian.org/debian/pool/main/n/ncurses/libtinfo6_6.1+20190803-1_amd64.deb \
    && dpkg -i *.deb \
    && rm *.deb \
    && chmod +x /opt/toolchains/dc/kos/environ.sh

RUN sed -i '1isource /opt/toolchains/dc/kos/environ.sh\' /etc/bash.bashrc \
    && echo 'source /opt/toolchains/dc/kos/environ.sh' >> /root/.bashrc 

WORKDIR /src
COPY entry.sh /usr/local/bin/
RUN rm -rf /usr/share/locale /usr/share/man /usr/share/doc && \
    chmod +x /usr/local/bin/entry.sh
ENTRYPOINT ["entry.sh"]
SHELL ["/bin/bash", "-l", "-c", "source /opt/toolchains/dc/kos/environ.sh"]
CMD ["bash"]
