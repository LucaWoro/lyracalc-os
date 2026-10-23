#!/bin/bash
# Cross-build TIC-80 v1.1.2837 for Ubuntu 24.04 armhf on an Ubuntu 24.04 x86_64 host.
# SDL2 is linked statically; X11, ALSA and libcurl are linked by soname only.
#   ./build.sh [WORKDIR]      result: WORKDIR/tic80
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
W=${1:-$HOME/tic80-build}
mkdir -p "$W" && cd "$W"
sudo apt-get install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf libc6-dev-armhf-cross \
  cmake make git libx11-dev libxext-dev libasound2-dev libcurl4-openssl-dev
if [ ! -d tic80 ]; then
  git clone --depth 1 --branch v1.1.2837 --recurse-submodules --shallow-submodules https://github.com/nesbox/TIC-80 tic80
  for p in "$HERE"/patches/*.patch; do git -C tic80 apply "$p"; done
fi

# host headers and empty armhf libraries with the target sonames
mkdir -p sysroot/lib sysroot/include emptypc
ln -sfn /usr/include/X11 sysroot/include/X11
ln -sfn /usr/include/alsa sysroot/include/alsa
ln -sfn /usr/include/x86_64-linux-gnu/curl sysroot/include/curl
stub() {   # name major full source
  echo "$4" > stub.c
  arm-linux-gnueabihf-gcc -shared -fPIC -Wl,-soname,lib$1.so.$2 -o sysroot/lib/lib$1.so.$3 stub.c
  ln -sf lib$1.so.$3 sysroot/lib/lib$1.so.$2; ln -sf lib$1.so.$3 sysroot/lib/lib$1.so
}
stub X11 6 6.4.0 'void x11_stub(void){}'
stub Xext 6 6.4.0 'void xext_stub(void){}'
stub asound 2 2.0.0 'int snd_pcm_recover(void*p,int e,int s){return 0;}'
stub curl 4 4.8.0 'void *curl_easy_init(void){return 0;} int curl_easy_setopt(void*h,int o,...){return 0;}
int curl_easy_getinfo(void*h,int i,...){return 0;} void curl_easy_cleanup(void*h){} int curl_global_init(long f){return 0;}
void *curl_multi_init(void){return 0;} int curl_multi_add_handle(void*m,void*e){return 0;}
void *curl_multi_info_read(void*m,int*q){return 0;} int curl_multi_perform(void*m,int*r){return 0;}
int curl_multi_wait(void*m,void*f,unsigned n,int t,int*r){return 0;} void *curl_slist_append(void*l,const char*s){return 0;}
void curl_slist_free_all(void*l){}'

cat > toolchain.cmake << TEOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)
set(CMAKE_FIND_ROOT_PATH /usr/arm-linux-gnueabihf $W/sysroot)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_C_FLAGS_INIT "-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -I$W/sysroot/include -DTIC80_NO_INTEGER_SCALE")
set(CMAKE_CXX_FLAGS_INIT "-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -I$W/sysroot/include")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-L$W/sysroot/lib")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-L$W/sysroot/lib")
TEOF

mkdir -p build && cd build
PKG_CONFIG_LIBDIR=$W/emptypc cmake ../tic80 -DCMAKE_TOOLCHAIN_FILE=$W/toolchain.cmake -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DBUILD_SDL=ON -DBUILD_SDLGPU=OFF -DBUILD_SOKOL=OFF -DBUILD_LIBRETRO=OFF -DBUILD_DEMO_CARTS=OFF \
  -DBUILD_PLAYER=OFF -DBUILD_PRO=OFF -DBUILD_STUB=OFF -DBUILD_WITH_MRUBY=OFF \
  -DSDL_WAYLAND=OFF -DSDL_PULSEAUDIO=OFF -DSDL_PIPEWIRE=OFF -DSDL_JACK=OFF -DSDL_SNDIO=OFF -DSDL_ESD=OFF \
  -DSDL_ARTS=OFF -DSDL_NAS=OFF -DSDL_KMSDRM=OFF -DSDL_OPENGL=OFF -DSDL_OPENGLES=OFF -DSDL_VULKAN=OFF \
  -DSDL_DIRECTFB=OFF -DSDL_LIBUDEV=OFF -DSDL_DBUS=OFF -DSDL_IBUS=OFF -DSDL_HIDAPI=OFF -DSDL_RPI=OFF \
  -DSDL_X11=ON -DSDL_X11_SHARED=ON -DSDL_ALSA=ON -DSDL_ALSA_SHARED=ON \
  -DHAVE_XGENERICEVENT=1 -DSDL_VIDEO_DRIVER_X11_HAS_XKBKEYCODETOKEYSYM=1 \
  -DCURL_LIBRARY=$W/sysroot/lib/libcurl.so -DCURL_INCLUDE_DIR=$W/sysroot/include
make -j"$(nproc)" tic80
arm-linux-gnueabihf-strip -o "$W/tic80" bin/tic80
echo "Done: $W/tic80"
