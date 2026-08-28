FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive
RUN printf '%s\n' \
      'deb http://mirrors.aliyun.com/ubuntu bionic main restricted universe multiverse' \
      'deb http://mirrors.aliyun.com/ubuntu bionic-updates main restricted universe multiverse' \
      'deb http://mirrors.aliyun.com/ubuntu bionic-security main restricted universe multiverse' \
      > /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends bc bison build-essential flex libssl-dev libncurses5-dev gcc-aarch64-linux-gnu ca-certificates cpio gzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
