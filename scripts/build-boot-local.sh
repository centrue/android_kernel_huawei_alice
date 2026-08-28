#!/usr/bin/env bash
set -euo pipefail

# Build only the ARM64 kernel in an Ubuntu 18.04 container and replace the
# kernel payload in prebuilt/base-boot.img. The Android system/vendor tree is
# not required and is never built.

ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-centrue-alice-kernel-builder:18.04}"
OUTDIR="${OUTDIR:-${ROOTDIR}/out-boot}"
ENABLE_TCPMSS=0
JOBS="${JOBS:-$(nproc)}"
MAGISKBOOT="${MAGISKBOOT:-}"

while [ $# -gt 0 ]; do
    case "$1" in
        --enable-tcpmss) ENABLE_TCPMSS=1; shift ;;
        --jobs) JOBS="$2"; shift 2 ;;
        --magiskboot) MAGISKBOOT="$2"; shift 2 ;;
        --outdir) OUTDIR="$2"; shift 2 ;;
        -h|--help)
            sed -n '1,12p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

[ -f "${ROOTDIR}/prebuilt/base-boot.img" ] || {
    echo "!! missing prebuilt/base-boot.img" >&2; exit 1; }
[ -n "${MAGISKBOOT}" ] && [ -x "${MAGISKBOOT}" ] || {
    echo "!! pass --magiskboot /path/to/magiskboot (an executable)" >&2; exit 1; }

mkdir -p "${OUTDIR}"
docker build -t "${IMAGE}" "${ROOTDIR}/docker"
docker run --rm \
    -e ENABLE_TCPMSS="${ENABLE_TCPMSS}" \
    -e JOBS="${JOBS}" \
    -v "${ROOTDIR}:/src" \
    -v "${MAGISKBOOT}:/usr/local/bin/magiskboot:ro" \
    -v "${OUTDIR}:/out" \
    "${IMAGE}" bash -ceu '
        cd /src
        export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
        make alice_defconfig
        if [ "$ENABLE_TCPMSS" = 1 ]; then
            sed -i "s/^# CONFIG_NETFILTER_XT_TARGET_TCPMSS is not set/CONFIG_NETFILTER_XT_TARGET_TCPMSS=y/" .config
        fi
        make olddefconfig
        make -j"$JOBS" Image
        cp arch/arm64/boot/Image /out/Image
        cp prebuilt/base-boot.img /out/base-boot.img
        cd /out
        magiskboot unpack base-boot.img
        cp Image kernel
        magiskboot repack base-boot.img boot.img
        sha256sum boot.img | tee boot.img.sha256
    '

echo "boot image: ${OUTDIR}/boot.img"
