# syntax=docker/dockerfile:1.6
ARG ALPINE_VERSION=3.24
ARG ZBX_SOURCES=https://github.com/zabbix/zabbix.git
ARG ZBX_REF=master
ARG ZBX_DOCKER_REF=trunk

# Templates de config e entrypoint oficiais (zabbix-docker)
FROM alpine:${ALPINE_VERSION} AS docker-src
ARG ZBX_DOCKER_REF
RUN apk add --no-cache git && \
    git -c advice.detachedHead=false clone --depth 1 --branch "${ZBX_DOCKER_REF}" \
        https://github.com/zabbix/zabbix-docker.git /src

# Entrypoint em Go do proxy SQLite3
FROM golang:1.25-alpine AS entrypoint-builder
COPY --from=docker-src /src/templates/entrypoints /src
WORKDIR /src
RUN CGO_ENABLED=0 go build -buildvcs=false -trimpath -ldflags="-s -w -buildid=" \
        -o /out/docker-entrypoint ./cmd/proxy-sqlite3

# Compilacao do zabbix_proxy com --with-apm
FROM alpine:${ALPINE_VERSION} AS builder
ARG ZBX_SOURCES
ARG ZBX_REF
ARG BUILD_JOBS

ENV CFLAGS="-O2 -fPIE -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -pipe" \
    LDFLAGS="-pie -Wl,-z,relro,-z,now,-z,defs -Wl,--as-needed"

RUN apk add --no-cache \
        bash coreutils git autoconf automake make g++ linux-headers pkgconf \
        c-ares-dev curl-dev libevent-dev libssh-dev libxml2-dev net-snmp-dev \
        openipmi-dev openldap-dev openssl-dev pcre2-dev sqlite-dev unixodbc-dev zlib-dev \
        grpc-dev grpc-plugins protobuf-dev protoc

RUN git -c advice.detachedHead=false clone --depth 1 --branch "${ZBX_REF}" \
        "${ZBX_SOURCES}" /build/zabbix

WORKDIR /build/zabbix

RUN set -eux && \
    rev="$(git rev-parse --short HEAD || echo unknown)" && \
    sed -i "s/{ZABBIX_REVISION}/${rev}/g" include/version.h && \
    ./bootstrap.sh && \
    ./configure \
        --datadir=/usr/lib \
        --libdir=/usr/lib/zabbix \
        --prefix=/usr \
        --sysconfdir=/etc/zabbix \
        --enable-ipv6 \
        --enable-agent \
        --enable-proxy \
        --with-apm \
        --with-sqlite3 \
        --with-ares \
        --with-ldap \
        --with-libcurl \
        --with-libpcre2 \
        --with-libxml2 \
        --with-net-snmp \
        --with-openipmi \
        --with-openssl \
        --with-ssh \
        --with-unixodbc \
        --silent && \
    jobs="${BUILD_JOBS:-$(nproc)}" && \
    make -j"${jobs}" -s dbschema && \
    make -j"${jobs}" -s

# Empacotamento separado para reaproveitar o cache da compilacao
RUN set -eux && \
    mkdir -p /out/sbin /out/bin /out/conf /out/database && \
    cat database/sqlite3/schema.sql | gzip -c > /out/database/create.sql.gz && \
    strip src/zabbix_proxy/zabbix_proxy src/zabbix_get/zabbix_get src/zabbix_sender/zabbix_sender && \
    mv src/zabbix_proxy/zabbix_proxy /out/sbin/ && \
    mv src/zabbix_get/zabbix_get src/zabbix_sender/zabbix_sender /out/bin/ && \
    cp conf/zabbix_proxy.conf /out/conf/zabbix_proxy.conf.dist

# Templates oficiais mais o fragmento de APM
COPY --from=docker-src /src/templates/config/proxy/ /out/conf/
COPY zabbix_proxy_apm.conf /out/conf/zabbix_proxy_apm.conf
RUN printf '\nInclude=/etc/zabbix/zabbix_proxy_apm.conf\n' >> /out/conf/zabbix_proxy.conf

# Imagem final
FROM alpine:${ALPINE_VERSION}

ARG ZBX_REF
ENV TERM=xterm \
    MIBDIRS=/usr/share/snmp/mibs:/var/lib/zabbix/mibs MIBS=+ALL \
    NMAP_PRIVILEGED= \
    ZABBIX_USER_HOME_DIR=/var/lib/zabbix \
    ZABBIX_CONF_DIR=/etc/zabbix

ENV ZBX_FPINGLOCATION=/usr/sbin/fping \
    ZBX_LOADMODULEPATH=${ZABBIX_USER_HOME_DIR}/modules \
    ZBX_SNMPTRAPPERFILE=${ZABBIX_USER_HOME_DIR}/snmptraps/snmptraps.log \
    ZBX_SSHKEYLOCATION=${ZABBIX_USER_HOME_DIR}/ssh_keys/ \
    ZBX_SSLCERTLOCATION=${ZABBIX_USER_HOME_DIR}/ssl/certs/ \
    ZBX_SSLKEYLOCATION=${ZABBIX_USER_HOME_DIR}/ssl/keys/ \
    ZBX_SSLCALOCATION=${ZABBIX_USER_HOME_DIR}/ssl/ssl_ca_internal/

LABEL org.opencontainers.image.title="Zabbix proxy (SQLite3, APM)" \
      org.opencontainers.image.description="Zabbix proxy 8.0 compiled with --with-apm (OTLP/gRPC collector)" \
      org.opencontainers.image.licenses="AGPL-3.0-only" \
      com.zabbix.product.ref="${ZBX_REF}"

COPY --chmod=0755 --from=entrypoint-builder /out/docker-entrypoint /usr/bin/docker-entrypoint
COPY --from=builder /out/sbin/zabbix_proxy /usr/sbin/zabbix_proxy
COPY --from=builder /out/bin/ /usr/bin/
COPY --from=builder /out/conf/ ${ZABBIX_CONF_DIR}/
COPY --from=builder /out/database/ /usr/share/doc/zabbix-proxy-sqlite3/

RUN set -eux && \
    apk add --no-cache --no-logfile --clean-protected \
        bash tzdata c-ares krb5 libcap libcurl libevent libldap libssh libxml2 \
        net-snmp-agent-libs openipmi-libs openssl pcre2 sqlite-libs unixodbc zlib \
        fping iputils nmap traceroute \
        grpc-cpp protobuf && \
    addgroup --system --gid 1995 zabbix && \
    adduser --system --gecos "Zabbix monitoring system" --disabled-password \
        --uid 1997 --ingroup zabbix --shell /sbin/nologin \
        --home ${ZABBIX_USER_HOME_DIR} zabbix && \
    chgrp zabbix /usr/bin/nmap && \
    setcap cap_net_raw+eip /usr/bin/nmap && \
    chmod u+s /usr/sbin/fping && \
    mkdir -p ${ZABBIX_CONF_DIR} \
        ${ZABBIX_USER_HOME_DIR}/db_data \
        ${ZABBIX_USER_HOME_DIR}/enc \
        ${ZABBIX_USER_HOME_DIR}/enc_internal \
        ${ZABBIX_USER_HOME_DIR}/mibs \
        ${ZABBIX_USER_HOME_DIR}/modules \
        ${ZABBIX_USER_HOME_DIR}/snmptraps \
        ${ZABBIX_USER_HOME_DIR}/ssh_keys \
        ${ZABBIX_USER_HOME_DIR}/ssl/certs \
        ${ZABBIX_USER_HOME_DIR}/ssl/keys \
        ${ZABBIX_USER_HOME_DIR}/ssl/ssl_ca \
        ${ZABBIX_USER_HOME_DIR}/ssl/ssl_ca_internal \
        /usr/lib/zabbix/externalscripts && \
    chown --quiet -R zabbix:0 ${ZABBIX_CONF_DIR}/zabbix_proxy_modules.conf ${ZABBIX_USER_HOME_DIR}/ && \
    chmod -R g=u ${ZABBIX_CONF_DIR}/zabbix_proxy_modules.conf ${ZABBIX_USER_HOME_DIR}/ && \
    chown --quiet zabbix:0 ${ZABBIX_CONF_DIR}/ && \
    chmod g=u ${ZABBIX_CONF_DIR} && \
    /usr/sbin/zabbix_proxy -V && \
    ldd /usr/sbin/zabbix_proxy | grep -q 'libgrpc++'

EXPOSE 10051/tcp 4317/tcp

WORKDIR ${ZABBIX_USER_HOME_DIR}

VOLUME ["${ZABBIX_USER_HOME_DIR}/snmptraps"]

USER 1997

ENTRYPOINT ["/usr/bin/docker-entrypoint"]

CMD ["/usr/sbin/zabbix_proxy", "--foreground", "-c", "/etc/zabbix/zabbix_proxy.conf"]
