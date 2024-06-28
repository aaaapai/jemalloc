#!/bin/sh
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
elif [ "$BUILD_ARCH" == "x64" ]; then
  export NDK_ABI=x86_64 NDK_TARGET=x86_64
fi

export TARGET=$NDK_TARGET-linux-android$NDK_SUFFIX
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64
export CFLAGS="-fno-rtti -Wno-int-conversion -fwhole-program-vtables"
export CXXFLAGS="-fno-rtti -D__GCC_HAVE_SYNC_COMPARE_AND_SWAP_4=1"
export ANDROID_INCLUDE=$TOOLCHAIN/sysroot/usr/include
export CPPFLAGS="-I$ANDROID_INCLUDE -I$ANDROID_INCLUDE/$TARGET "
export PATH=$TOOLCHAIN/bin:$PATH
export LDFLAGS="-L$TOOLCHAIN/sysroot/usr/lib/${TARGET}/${API}"
export thecc=$TOOLCHAIN/bin/${TARGET}${API}-clang
export thecxx=$TOOLCHAIN/bin/${TARGET}${API}-clang++
export DLLTOOL=/usr/bin/llvm-dlltool-18
export CXXFILT=$TOOLCHAIN/bin/llvm-cxxfilt
export NM=$TOOLCHAIN/bin/llvm-nm
export CC=$thecc
export CXX=$thecxx
export AR=$TOOLCHAIN/bin/llvm-ar
export AS=$TOOLCHAIN/bin/llvm-as
export LD=$TOOLCHAIN/bin/ld.lld
export OBJCOPY=$TOOLCHAIN/bin/llvm-objcopy
export OBJDUMP=$TOOLCHAIN/bin/llvm-objdump
export READELF=$TOOLCHAIN/bin/llvm-readelf
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip
export LINK=$TOOLCHAIN/bin/llvm-link

for i in autoconf; do
    echo "$i"
    $i
    if [ $? -ne 0 ]; then
	echo "Error $? in $i"
	exit 1
    fi
done

echo "./configure --enable-autogen \"$@\""
if [ $? -ne 0 ]; then
    echo "Error $? in ./configure"
    exit 1
fi

./configure \
  --enable-autogen "$@" \
  --host=$TARGET \
  --prefix=${PWD}/build_android-$BUILD_ARCH \
  || error_code=$?

if [[ "$error_code" -ne 0 ]]; then
  echo "\n\nCONFIGURE ERROR $error_code , config.log:"
  cat config.log
  exit $error_code
fi
