ARG HANA_BASE_URL="https://d149oh3iywgk04.cloudfront.net/hanaexpress/"
ARG HANA_VERSION="2.00.045.00.20200121.1"

ARG MASTER_PASSWORD="1UnsafePassword!"

FROM ubuntu:16.04 AS base

ARG HANA_BASE_URL
ARG HANA_VERSION
ARG MASTER_PASSWORD

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install Hana Dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq -y software-properties-common && \
    apt-add-repository ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq -y install locales libatomic1 gawk libltdl7 libstdc++6 libaio1 zip unzip curl libnuma1 xgrep && \
    apt-get remove -qq  -y software-properties-common && \
    apt-get autoremove -qq -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set the Locale or everything fails. (Bails out early @ ExternalProgramConfiguration)
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8


FROM base AS builder

ARG HANA_BASE_URL
ARG HANA_VERSION
ARG MASTER_PASSWORD

COPY fetch.sh /
RUN /bin/bash /fetch.sh
COPY install.sh /
RUN /bin/bash /install.sh

FROM base
COPY --from=builder /hana /hana

