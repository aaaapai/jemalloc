#!/bin/bash
set -e

export API=24

if   [ "$BUILD_ARCH" == "arm64" ]; then
  export NDK_ABI=arm64-v8a NDK_TARGET=aarch64
elif [ "$BUILD_ARCH" == "arm32" ]; then
  export NDK_ABI=armeabi-v7a NDK_TARGET=armv7a NDK_SUFFIX=eabi
elif [ "$BUILD_ARCH" == "x86" ]; then
  export NDK_ABI=x86 NDK_TARGET=i686
elif [ "$BUILD_ARCH" == "x64" ]; then
  export NDK_ABI=x86_64 NDK_TARGET=x86_64
fi

export TARGET=$NDK_TARGET-linux-android
export TOOLCHAIN=$ANDROID_NDK_LATEST_HOME/toolchains/llvm/prebuilt/linux-x86_64
export CFLAGS="-O3 -Wno-array-bounds -flto=thin -Wno-int-conversion -fwhole-program-vtables -Wno-ignored-attributes -Wno-array-bounds -Wno-unknown-warning-option -Wno-ignored-attributes -flto=thin -Wno-int-conversion -fwhole-program-vtables -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -D__GCC_HAVE_SYNC_COMPARE_AND_SWAP_4=1"
export CXXFLAGS="-D__GCC_HAVE_SYNC_COMPARE_AND_SWAP_4=1"
export ANDROID_INCLUDE=$TOOLCHAIN/sysroot/usr/include
export CPPFLAGS="-I$ANDROID_INCLUDE -I$ANDROID_INCLUDE/$TARGET -mllvm -polly"
export PATH=$TOOLCHAIN/bin:$PATH
export LDFLAGS="-L$TOOLCHAIN/sysroot/usr/lib/${TARGET}/${API} -lc++abi -lc++_static -lc -lm"
export thecc=$TOOLCHAIN/bin/${TARGET}${API}-clang
export thecxx=$TOOLCHAIN/bin/${TARGET}${API}-clang++
export DLLTOOL=$TOOLCHAIN/bin/llvm-dlltool
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

<< EOF
echo "./configure --enable-autogen \"$@\""
if [ $? -ne 0 ]; then
    echo "Error $? in ./configure"
    exit 1
fi
EOF

./autogen.sh
./configure \
  --enable-autogen "$@" \
  --host=$TARGET \
  --disable-initial-exec-tls \
  --with-jemalloc-prefix='je_' \
  --disable-stats \
  --disable-fill \
  --with-lg-page=16 \
  --enable-doc=no \
  --prefix=${PWD}/build_android-$BUILD_ARCH \
  || error_code=$?

if [ "$error_code" -ne 0 ]; then
    echo "Error $error_code in ./configure"
	cat config.log
    exit $error_code
fi

make

if [[ "$error_code" -ne 0 ]]; then
  echo "\n\nCONFIGURE ERROR $error_code , config.log:"
  cat config.log
  exit $error_code
fi

cd lib
find ./ -name '*' -execdir ${TOOLCHAIN}/bin/llvm-strip {} \;
