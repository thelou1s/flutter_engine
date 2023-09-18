# Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#! /bin/bash
#
#编译依赖
#sudo apt install g++-multilib git python3 curl

HOST_OS=linux
NDK_HOME=`pwd`/ndk/$HOST_OS/4.0/native
NDK_TOOLCHAIN_CMAKE=$NDK_HOME/build/cmake/ohos.toolchain.cmake
NDK_SDK_CMAKE=$NDK_HOME/build/cmake/sdk_native_platforms.cmake
export PATH=$NDK_HOME/build-tools/cmake/bin:$NDK_HOME/llvm/bin:$PATH
export PATH=$(pwd)/depot_tools/:$PATH

#debug|profile|rlease
RT_MODE="debug"
TARGET_OS="ohos"
TARGET_ARCH="arm64"
OPT=" --unoptimized  --no-lto --no-goma  --no-prebuilt-dart-sdk "
HOST_OPT=" --unoptimized  --no-lto --no-goma  "

#aarch64-linux-ohos  arm-linux-ohos 
TARGET_TRIPLE="aarch64-linux-ohos"
OUTPUT="out/$TARGET_OS""_debug_unopt_""$TARGET_ARCH"

  config_debug_env()
  {
    RT_MODE="debug"
    TARGET_ARCH="arm64"
   src/flutter/tools/gn \
      --target-sysroot $NDK_HOME/sysroot \
      --target-toolchain $NDK_HOME/llvm \
      --target-triple $TARGET_TRIPLE \
      --ohos   --ohos-cpu $TARGET_ARCH  \
      --runtime-mode $RT_MODE $OPT \
      --embedder-for-target \
      --disable-desktop-embeddings --no-build-embedder-examples \
      --verbose
  }
  config_profile_env()
  {
    RT_MODE="profile"
    TARGET_ARCH="arm64"
    OPT=" --no-goma  --no-prebuilt-dart-sdk "
   src/flutter/tools/gn \
      --target-sysroot $NDK_HOME/sysroot \
      --target-toolchain $NDK_HOME/llvm \
      --target-triple $TARGET_TRIPLE \
      --ohos   --ohos-cpu $TARGET_ARCH \
      --runtime-mode $RT_MODE $OPT \
      --embedder-for-target \
      --disable-desktop-embeddings --no-build-embedder-examples \
      --verbose
  }
  config_release_env()
  {
    RT_MODE="release"
    TARGET_OS="linux"
    TARGET_ARCH="arm64"
    OPT=" --no-goma  --no-prebuilt-dart-sdk "
   src/flutter/tools/gn \
      --target-sysroot $NDK_HOME/sysroot \
      --target-toolchain $NDK_HOME/llvm \
      --target-triple $TARGET_TRIPLE \
      --ohos   --ohos-cpu $TARGET_ARCH  \
      --runtime-mode $RT_MODE $OPT \
      --embedder-for-target \
      --disable-desktop-embeddings --no-build-embedder-examples \
      --verbose
  }
  config_host_debug_env()
  {
      #--embedder-for-target  \
    src/flutter/tools/gn  $HOST_OPT  \
      --runtime-mode $RT_MODE  \
      --no-dart-version-git-info  \
      --full-dart-sdk \
      --no-build-web-sdk \
      --disable-desktop-embeddings --no-build-embedder-examples \
      --verbose  --trace-gn
  }

config ()
{
config_debug_env 
#  config_host_debug_env;
#  config_profile_env
  config_release_env
}

compile()
{
  #ninja -C "$OUTPUT" -j 4 && find . -name libflutter_engine.so
  find src/out -mindepth 1 -maxdepth 1 -type d | xargs -n 1 sh -c 'ninja -C $0 || exit 255'
}

config ;
compile ;

