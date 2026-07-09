#!/bin/sh

set -e
set -x

ARCH="$1"

SOURCE_DIR="$2"
BUILD_DIR=$(echo "$(cd "$(dirname "$3")"; pwd -P)/$(basename "$3")")
OPENSSL_DIR="$4"

openssl_crypto_library="${OPENSSL_DIR}/lib/libcrypto.a"
options=""
options="$options -DOPENSSL_FOUND=1"
options="$options -DOPENSSL_CRYPTO_LIBRARY=${openssl_crypto_library}"
options="$options -DOPENSSL_INCLUDE_DIR=${OPENSSL_DIR}/src/include"
options="$options -DCMAKE_BUILD_TYPE=Release"
options="$options -DIOS_DEPLOYMENT_TARGET=13.0"

# Bazel genrule runs with PATH=/bin:/usr/bin, so resolve CPU count without
# relying on /usr/sbin being in PATH.
if [ -n "${TD_BUILD_JOBS:-}" ]; then
  BUILD_JOBS="$TD_BUILD_JOBS"
elif [ -x /usr/sbin/sysctl ]; then
  BUILD_JOBS="$(/usr/sbin/sysctl -n hw.ncpu)"
elif command -v getconf >/dev/null 2>&1; then
  BUILD_JOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
fi
case "$BUILD_JOBS" in
  ''|*[!0-9]*)
    BUILD_JOBS=8
    ;;
esac
if [ "$BUILD_JOBS" -lt 1 ]; then
  BUILD_JOBS=1
fi

MAX_BUILD_JOBS="${TD_MAX_BUILD_JOBS:-8}"
case "$MAX_BUILD_JOBS" in
  ''|*[!0-9]*)
    MAX_BUILD_JOBS=8
    ;;
esac
if [ "$MAX_BUILD_JOBS" -lt 1 ]; then
  MAX_BUILD_JOBS=8
fi
if [ "$BUILD_JOBS" -gt "$MAX_BUILD_JOBS" ]; then
  BUILD_JOBS="$MAX_BUILD_JOBS"
fi
if [ -z "$BUILD_JOBS" ]; then
  BUILD_JOBS=8
fi

cd "$BUILD_DIR"

# Generate source files
mkdir native-build
cd native-build
cmake -DTD_GENERATE_SOURCE_FILES=ON ../td
cmake --build . -- -j"$BUILD_JOBS"
cd ..

if [ "$ARCH" = "arm64" ]; then
  IOS_PLATFORMDIR="$(xcode-select -p)/Platforms/iPhoneOS.platform"
  IOS_SYSROOT=($IOS_PLATFORMDIR/Developer/SDKs/iPhoneOS*.sdk)
  cmake_arch="arm64"
  clang_target="arm64-apple-ios13.0"
  minimum_target_flag="-miphoneos-version-min=13.0"
  cmake_processor="aarch64"
elif [ "$ARCH" = "sim_arm64" ]; then
  IOS_PLATFORMDIR="$(xcode-select -p)/Platforms/iPhoneSimulator.platform"
  IOS_SYSROOT=($IOS_PLATFORMDIR/Developer/SDKs/iPhoneSimulator*.sdk)
  cmake_arch="arm64"
  clang_target="arm64-apple-ios13.0-simulator"
  minimum_target_flag="-miphonesimulator-version-min=13.0"
  cmake_processor="aarch64"
elif [ "$ARCH" = "sim_x86_64" ]; then
  IOS_PLATFORMDIR="$(xcode-select -p)/Platforms/iPhoneSimulator.platform"
  IOS_SYSROOT=($IOS_PLATFORMDIR/Developer/SDKs/iPhoneSimulator*.sdk)
  cmake_arch="x86_64"
  clang_target="x86_64-apple-ios13.0-simulator"
  minimum_target_flag="-miphonesimulator-version-min=13.0"
  cmake_processor="x86_64"
else
  echo "Unsupported architecture $ARCH"
  exit 1
fi

export CFLAGS="-arch ${cmake_arch} --target=${clang_target} ${minimum_target_flag}"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="$CFLAGS"

# Common build steps
mkdir build
cd build

touch toolchain.cmake
echo "set(CMAKE_SYSTEM_NAME Darwin)" >> toolchain.cmake
echo "set(CMAKE_SYSTEM_PROCESSOR ${cmake_processor})" >> toolchain.cmake
echo "set(CMAKE_OSX_ARCHITECTURES ${cmake_arch})" >> toolchain.cmake
echo "set(CMAKE_C_COMPILER $(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang)" >> toolchain.cmake
echo "set(CMAKE_CXX_COMPILER $(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++)" >> toolchain.cmake
echo "set(CMAKE_C_COMPILER_TARGET ${clang_target})" >> toolchain.cmake
echo "set(CMAKE_CXX_COMPILER_TARGET ${clang_target})" >> toolchain.cmake

cmake -G"Unix Makefiles" -DCMAKE_TOOLCHAIN_FILE=toolchain.cmake -DCMAKE_OSX_SYSROOT=${IOS_SYSROOT[0]} ../td $options
make tde2e -j"$BUILD_JOBS"
