# android_kernel_huawei_hi6210sft

## Local boot-only build

`scripts/build-boot-local.sh` follows the kernel phase of
`lineage_build`/`vendor/lineage/build/tasks/kernel.mk`. It reads
`TARGET_KERNEL_ARCH`, `TARGET_KERNEL_CONFIG`, `BOARD_KERNEL_IMAGE_NAME`, the
cross-compiler prefix, and boot geometry from the DarkJoker360
`BoardConfig.mk`; it does not guess or download a replacement compiler.

The kernel-only checkout does not contain Android's prebuilt GCC. Pass the
Android 8.1 GCC 4.9 directory (the one containing
`bin/aarch64-linux-android-gcc`) and an executable `magiskboot`:

```sh
./scripts/build-boot-local.sh \
  --toolchain-dir /path/to/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 \
  --magiskboot /path/to/magiskboot
```

Add `--enable-tcpmss` only for the comparison build. The resulting
`out-boot/boot.img` replaces the kernel in `prebuilt/base-boot.img`; no full
Android system/vendor tree is compiled. The script keeps the Android build's
out-of-tree `O=/out/kernel-out` layout, passes the arm64
`CFLAGS_MODULE=-fno-pic` compatibility flag, and builds `dtbs` when the
defconfig enables `CONFIG_OF`.
