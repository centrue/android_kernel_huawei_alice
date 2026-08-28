#!/usr/bin/env bash
set -euo pipefail

# Build only the ARM64 kernel in an Ubuntu 18.04 container and export the
# resulting Image. Boot-image unpacking/repacking is intentionally left to the
# caller, so this script has no boot-image tool dependency.
#
# The kernel parameters are read from the synced device tree's BoardConfig.mk;
# this script does not invent a config, image target, or cross compiler prefix.
# Because the kernel-only checkout has no Android prebuilts,
# pass the exact AOSP/Lineage GCC 4.9 directory with --toolchain-dir.
#
# Example:
#   ./scripts/build-boot-local.sh \
#     --toolchain-dir /path/to/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9

ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-centrue-alice-kernel-builder:18.04}"
OUTDIR="${OUTDIR:-${ROOTDIR}/out-kernel}"
ENABLE_TCPMSS=0
JOBS="${JOBS:-$(nproc)}"
BOARD_CONFIG="${BOARD_CONFIG:-${ROOTDIR}/../android_device_huawei_alice_clone/BoardConfig.mk}"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-}"

while [ $# -gt 0 ]; do
    case "$1" in
        --enable-tcpmss) ENABLE_TCPMSS=1; shift ;;
        --jobs) JOBS="$2"; shift 2 ;;
        --outdir) OUTDIR="$2"; shift 2 ;;
        --board-config) BOARD_CONFIG="$2"; shift 2 ;;
        --toolchain-dir) TOOLCHAIN_DIR="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

[ -f "${BOARD_CONFIG}" ] || {
    echo "!! missing BoardConfig.mk: ${BOARD_CONFIG}" >&2
    echo "   pass --board-config /path/to/DarkJoker360/android_device_huawei_alice/BoardConfig.mk" >&2
    exit 1
}
if [ -z "${TOOLCHAIN_DIR}" ] || [ ! -d "${TOOLCHAIN_DIR}/bin" ]; then
    echo "!! pass --toolchain-dir to the Android 8.1 AOSP GCC directory" >&2
    echo "   it must contain bin/aarch64-linux-android-gcc" >&2
    exit 1
fi

# These are not guessed kernel settings.  They are read from the same
# DarkJoker360 device tree that lineage_build syncs.  The full Android build
# normally consumes these through lunch; a kernel-only build must make the
# equivalent values explicit.
mkvar() {
    local key="$1"
    sed -n -E "s/^[[:space:]]*${key}[[:space:]]*:?=[[:space:]]*(.*)[[:space:]]*$/\1/p" \
        "${BOARD_CONFIG}" | tail -n 1
}

KERNEL_ARCH="$(mkvar TARGET_KERNEL_ARCH)"
KERNEL_CONFIG="$(mkvar TARGET_KERNEL_CONFIG)"
KERNEL_IMAGE="$(mkvar BOARD_KERNEL_IMAGE_NAME)"
CROSS_COMPILE_PREFIX="$(mkvar TARGET_KERNEL_CROSS_COMPILE_PREFIX)"

[ "${KERNEL_ARCH}" = arm64 ] || {
    echo "!! BoardConfig TARGET_KERNEL_ARCH=${KERNEL_ARCH@Q}; expected arm64" >&2; exit 1; }
[ "${KERNEL_CONFIG}" = alice_defconfig ] || {
    echo "!! BoardConfig TARGET_KERNEL_CONFIG=${KERNEL_CONFIG@Q}; expected alice_defconfig" >&2; exit 1; }
[ "${KERNEL_IMAGE}" = Image ] || {
    echo "!! BoardConfig BOARD_KERNEL_IMAGE_NAME=${KERNEL_IMAGE@Q}; expected Image" >&2; exit 1; }
[ "${CROSS_COMPILE_PREFIX}" = aarch64-linux-android- ] || {
    echo "!! BoardConfig TARGET_KERNEL_CROSS_COMPILE_PREFIX=${CROSS_COMPILE_PREFIX@Q}; expected aarch64-linux-android-" >&2
    exit 1
}

if [ ! -x "${TOOLCHAIN_DIR}/bin/${CROSS_COMPILE_PREFIX}gcc" ]; then
    echo "!! missing ${TOOLCHAIN_DIR}/bin/${CROSS_COMPILE_PREFIX}gcc" >&2
    exit 1
fi

mkdir -p "${OUTDIR}"
docker build -t "${IMAGE}" "${ROOTDIR}/docker"
docker run --rm \
    -e ENABLE_TCPMSS="${ENABLE_TCPMSS}" \
    -e JOBS="${JOBS}" \
    -e KERNEL_ARCH="${KERNEL_ARCH}" \
    -e KERNEL_CONFIG="${KERNEL_CONFIG}" \
    -e KERNEL_IMAGE="${KERNEL_IMAGE}" \
    -e CROSS_COMPILE_PREFIX="${CROSS_COMPILE_PREFIX}" \
    -v "${ROOTDIR}:/src" \
    -v "${TOOLCHAIN_DIR}:/opt/android-toolchain:ro" \
    -v "${OUTDIR}:/out" \
    "${IMAGE}" bash -ceu '
        cd /src
        export ARCH="$KERNEL_ARCH"
        export CROSS_COMPILE="/opt/android-toolchain/bin/$CROSS_COMPILE_PREFIX"
        compiler_version="$("${CROSS_COMPILE}gcc" -dumpversion)"
        case "$compiler_version" in
            4.9*) printf "compiler: "; "${CROSS_COMPILE}gcc" --version | head -1 ;;
            *) echo "!! expected Android GCC 4.9, got $compiler_version" >&2; exit 1 ;;
        esac
        # This is the same out-of-tree KERNEL_OUT and arm64 module flag used
        # by vendor/lineage/build/tasks/kernel.mk during `make bacon`.
        KERNEL_OUT=/out/kernel-out
        mkdir -p "$KERNEL_OUT"
        make O="$KERNEL_OUT" CFLAGS_MODULE="-fno-pic" "$KERNEL_CONFIG"
        if [ "$ENABLE_TCPMSS" = 1 ]; then
            sed -i "s/^# CONFIG_NETFILTER_XT_TARGET_TCPMSS is not set/CONFIG_NETFILTER_XT_TARGET_TCPMSS=y/" "$KERNEL_OUT/.config"
        fi
        make O="$KERNEL_OUT" CFLAGS_MODULE="-fno-pic" olddefconfig
        make O="$KERNEL_OUT" CFLAGS_MODULE="-fno-pic" -j"$JOBS" "$KERNEL_IMAGE"
        if grep -q "^CONFIG_OF=y" "$KERNEL_OUT/.config"; then
            make O="$KERNEL_OUT" CFLAGS_MODULE="-fno-pic" -j"$JOBS" dtbs
        fi
        cp "$KERNEL_OUT/arch/$KERNEL_ARCH/boot/$KERNEL_IMAGE" /out/Image
        sha256sum /out/Image | tee /out/Image.sha256
    '

echo "kernel image: ${OUTDIR}/Image"
