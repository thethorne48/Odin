# This is the release of Alpine to use.
ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION}

# Create Consul user and necessary directories
RUN addgroup consul && adduser -S consul -G consul
RUN echo "consul    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN mkdir -p /consul/config /consul/data /consul/logs /config/keys
RUN chown -R consul:consul /usr/local

# Add GPG Key
COPY ./hashicorp.asc /consul/keys/hashicorp.asc
# Set Consul configuration file
ARG config_file=/consul/config/consul.hcl
ARG keys_file=/consul/config/keys.hcl

# This is the release of Consul to pull in.
ARG CONSUL_VERSION

# Server config
ARG DATACENTER
ARG DOMAIN
ARG NODE_NAME

# This is the location of the releases.
ENV HASHICORP_RELEASES=https://releases.hashicorp.com

# Install Consul
RUN set -eux && \
    apk update && apk upgrade --no-cache && apk add --no-cache ca-certificates && \
    apk add --no-cache --virtual .build_deps gnupg sudo unzip wget
USER consul:consul
RUN gpg --import /consul/keys/hashicorp.asc && \
    mkdir -p /home/consul/build && \
    cd /home/consul/build && \
    apkArch="$(apk --print-arch)" && \
    case "${apkArch}" in \
        aarch64) consulArch='arm64' ;; \
        armhf) consulArch='arm' ;; \
        x86) consulArch='386' ;; \
        x86_64) consulArch='amd64' ;; \
        *) echo >&2 "error: unsupported architecture: ${apkArch} (see ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/)" && exit 1 ;; \
    esac && \
    wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_${consulArch}.zip && \
    wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS && \
    wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig && \
    gpg --batch --verify consul_${CONSUL_VERSION}_SHA256SUMS.sig consul_${CONSUL_VERSION}_SHA256SUMS && \
    grep consul_${CONSUL_VERSION}_linux_${consulArch}.zip consul_${CONSUL_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip -d /usr/local/bin consul_${CONSUL_VERSION}_linux_${consulArch}.zip && \
    sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/consul && \
    rm -rf /home/consul/build && \
    # tiny smoke test to ensure the binary we downloaded runs
    consul version
USER root
RUN apk del .build_deps

# Configure TLS
WORKDIR /config/keys/ca
RUN consul tls ca create -name-constraint -domain=${DOMAIN}
WORKDIR /config/keys/server
RUN consul tls cert create -server -dc=${DATACENTER} -domain=${DOMAIN} -ca=/config/keys/ca/${DOMAIN}-agent-ca.pem -key=/config/keys/ca/${DOMAIN}-agent-ca-key.pem
WORKDIR /config/keys/client
RUN consul tls cert create -client -dc=${DATACENTER} -domain=${DOMAIN} -ca=/config/keys/ca/${DOMAIN}-agent-ca.pem -key=/config/keys/ca/${DOMAIN}-agent-ca-key.pem
WORKDIR /config/keys/cli
RUN consul tls cert create -cli -dc=${DATACENTER} -domain=${DOMAIN} -ca=/config/keys/ca/${DOMAIN}-agent-ca.pem -key=/config/keys/ca/${DOMAIN}-agent-ca-key.pem

# Copy config file
COPY ./consul.hcl ${config_file}
RUN chmod 640 ${config_file}

# Set configuration values
RUN echo "encrypt = \"$(consul keygen)\"" >> ${config_file} && \
   echo "datacenter = \"${DATACENTER}\"" >> ${config_file} && \
   echo "domain = \"${DOMAIN}\"" >> ${config_file} && \
   echo "node_name = \"${NODE_NAME}\"" >> ${config_file} && \
   echo "key_file = \"/config/keys/server/asgard-server-yggdrasil-0-key.pem\"" >> ${keys_file} && \
   echo "cert_file = \"/config/keys/server/asgard-server-yggdrasil-0.pem\"" >> ${keys_file} && \
   echo "ca_file = \"/config/keys/ca/yggdrasil-agent-ca.pem\"" >> ${keys_file}
# RUN cat ${config_file}
# RUN cat ${keys_file}


# Set directory ownership
RUN chown -R consul:consul /consul /config
USER consul:consul
RUN chmod 640 ${config_file}
RUN chmod -R 740 /config/keys

# 8300 - Server RPC is used for communication between Consul clients and servers for internal
# request forwarding.
# 8301-8302 - Serf LAN and WAN (WAN is used only by Consul servers) are used for gossip between
# Consul agents. LAN is within the datacenter and WAN is between just the Consul
# servers in all datacenters.
EXPOSE 8300-8302

# HTTP, HTTPS, and DNS (both TCP and UDP) are the primary interfaces that applications
# use to interact with Consul.
EXPOSE 8500-8501
EXPOSE 8600 8600/udp
# EXPOSE 53 53/udp
# EXPOSE 53

WORKDIR /home/consul
ENTRYPOINT [ "consul", "agent", "-config-dir=/consul/config/" ]
