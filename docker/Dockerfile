FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://archive.ubuntu.com/ubuntu|http://old-releases.ubuntu.com/ubuntu|g; s|http://security.ubuntu.com/ubuntu|http://old-releases.ubuntu.com/ubuntu|g' /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends bc bison build-essential flex libssl-dev libncurses5-dev gcc-aarch64-linux-gnu ca-certificates cpio gzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
