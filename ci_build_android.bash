#!/bin/bash
set -e

export ANDROID=1

if   [ "$BUILD_ARCH" == "arm64" ]; then
  export NDK_ABI=arm64-v8a NDK_TARGET=aarch64
elif [ "$BUILD_ARCH" == "arm32" ]; then
  export NDK_ABI=armeabi-v7a NDK_TARGET=armv7a NDK_SUFFIX=eabi
elif [ "$BUILD_ARCH" == "x86" ]; then
  export NDK_ABI=x86 NDK_TARGET=i686
  # Workaround: LWJGL 3 lacks of x86 Linux libraries
  mkdir -p bin/libs/native/linux/x86/org/lwjgl/glfw
  touch bin/libs/native/linux/x86/org/lwjgl/glfw/libglfw.so
elif [ "$LWJGL_BUILD_ARCH" == "x64" ]; then
  export NDK_ABI=x86_64 NDK_TARGET=x86_64
fi

export TARGET=$NDK_TARGET-linux-android$NDK_SUFFIX
export PATH=$PATH:$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64
export ANDROID_INCLUDE=$TOOLCHAIN/sysroot/usr/include

./autogen.sh
./configure
bash configure --host=$TARGET --prefix=$PWD/$NDK_TARGET-unknown-linux-android$NDK_SUFFIX CC=${TARGET}21-clang CXX=${TARGET}21-clang++ CPPFLAGS="-I$ANDROID_INCLUDE -I$ANDROID_INCLUDE/$TARGET -D__GCC_HAVE_SYNC_COMPARE_AND_SWAP_4=1" DLLTOOL=/usr/bin/llvm-dlltool-18 CXXFILT=$TOOLCHAIN/bin/llvm-cxxfilt NM=$TOOLCHAIN/bin/llvm-nm AR=$TOOLCHAIN/bin/llvm-ar AS=$TOOLCHAIN/bin/llvm-as LD=$TOOLCHAIN/bin/ld.lld OBJCOPY=$TOOLCHAIN/bin/llvm-objcopy OBJDUMP=$TOOLCHAIN/bin/llvm-objdump READELF=$TOOLCHAIN/bin/llvm-readelf RANLIB=$TOOLCHAIN/bin/llvm-ranlib STRIP=$TOOLCHAIN/bin/llvm-strip LINK=$TOOLCHAIN/bin/llvm-link LDFLAGS="-L$TOOLCHAIN/sysroot/usr/lib/${TARGET}/${API}" CFLAGS="-fwhole-program-vtables -Wno-int-conversion -Wno-error=implicit-function-declaration"
make -j4
