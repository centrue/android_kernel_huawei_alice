# android_kernel_huawei_hi6210sft

## Local boot-only build

`scripts/build-boot-local.sh` follows the kernel phase of
`lineage_build`/`vendor/lineage/build/tasks/kernel.mk`. It reads
`TARGET_KERNEL_ARCH`, `TARGET_KERNEL_CONFIG`, `BOARD_KERNEL_IMAGE_NAME`, and
the cross-compiler prefix from the DarkJoker360 `BoardConfig.mk`; it does not
guess or download a replacement compiler.

The kernel-only checkout does not contain Android's prebuilt GCC. Pass the
Android 8.1 GCC 4.9 directory (the one containing
`bin/aarch64-linux-android-gcc`):

```sh
./scripts/build-boot-local.sh \
  --toolchain-dir /path/to/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
```

Add `--enable-tcpmss` only for the comparison build. The resulting
`out-kernel/Image` is the raw kernel payload for your manual boot-image
replacement; `out-kernel/Image.sha256` records its checksum. No boot image is
unpacked or repacked, and no full Android system/vendor tree is compiled. The
script keeps the Android build's out-of-tree `O=/out/kernel-out` layout, passes
the arm64 `CFLAGS_MODULE=-fno-pic` compatibility flag, and builds `dtbs` when
the defconfig enables `CONFIG_OF`.
