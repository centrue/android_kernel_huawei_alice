FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive
# The Android cross compiler is deliberately not installed from Ubuntu here:
# the Lineage build obtains the pinned aarch64-linux-android-4.9 toolchain from
# the Android source tree. build-boot-local.sh mounts that exact directory and
# refuses to substitute Debian's aarch64-linux-gnu toolchain.
RUN printf '%s\n' \
      'deb http://mirrors.aliyun.com/ubuntu bionic main restricted universe multiverse' \
      'deb http://mirrors.aliyun.com/ubuntu bionic-updates main restricted universe multiverse' \
      'deb http://mirrors.aliyun.com/ubuntu bionic-security main restricted universe multiverse' \
      > /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends bc bison build-essential flex libssl-dev libncurses5-dev ca-certificates cpio gzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
