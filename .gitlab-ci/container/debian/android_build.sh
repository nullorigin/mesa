#!/usr/bin/env bash
# shellcheck disable=SC2086 # we want word splitting

set -ex

EPHEMERAL=(
    autoconf
    rdfind
    unzip
)

apt-get install -y --no-remove "${EPHEMERAL[@]}"

# Fetch the NDK and extract just the toolchain we want.
ndk=$ANDROID_NDK
curl -L --retry 4 -f --retry-all-errors --retry-delay 60 \
  -o $ndk.zip https://dl.google.com/android/repository/$ndk-linux.zip
unzip -d / $ndk.zip "$ndk/toolchains/llvm/*"
rm $ndk.zip
# Since it was packed as a zip file, symlinks/hardlinks got turned into
# duplicate files.  Turn them into hardlinks to save on container space.
rdfind -makehardlinks true -makeresultsfile false /${ndk}/
# Drop some large tools we won't use in this build.
find /${ndk}/ -type f | grep -E -i "clang-check|clang-tidy|lldb" | xargs rm -f

sh .gitlab-ci/container/create-android-ndk-pc.sh /$ndk zlib.pc "" "-lz" "1.2.3" $ANDROID_SDK_VERSION

sh .gitlab-ci/container/create-android-cross-file.sh /$ndk x86_64-linux-android x86_64 x86_64 $ANDROID_SDK_VERSION
sh .gitlab-ci/container/create-android-cross-file.sh /$ndk i686-linux-android x86 x86 $ANDROID_SDK_VERSION
sh .gitlab-ci/container/create-android-cross-file.sh /$ndk aarch64-linux-android aarch64 armv8 $ANDROID_SDK_VERSION
sh .gitlab-ci/container/create-android-cross-file.sh /$ndk arm-linux-androideabi arm armv7hl $ANDROID_SDK_VERSION armv7a-linux-androideabi

# Not using build-libdrm.sh because we don't want its cleanup after building
# each arch.  Fetch and extract now.
export LIBDRM_VERSION=libdrm-2.4.114
curl -L --retry 4 -f --retry-all-errors --retry-delay 60 \
  -O https://dri.freedesktop.org/libdrm/$LIBDRM_VERSION.tar.xz
tar -xf $LIBDRM_VERSION.tar.xz && rm $LIBDRM_VERSION.tar.xz

for arch in \
        x86_64-linux-android \
        i686-linux-android \
        aarch64-linux-android \
        arm-linux-androideabi ; do

    cd $LIBDRM_VERSION
    rm -rf build-$arch
    meson setup build-$arch \
          --cross-file=/cross_file-$arch.txt \
          --libdir=lib/$arch \
          -Dnouveau=disabled \
          -Dvc4=disabled \
          -Detnaviv=disabled \
          -Dfreedreno=disabled \
          -Dintel=disabled \
          -Dcairo-tests=disabled \
          -Dvalgrind=disabled
    meson install -C build-$arch
    cd ..
done

rm -rf $LIBDRM_VERSION

export LIBELF_VERSION=libelf-0.8.13
curl -L --retry 4 -f --retry-all-errors --retry-delay 60 \
  -O https://fossies.org/linux/misc/old/$LIBELF_VERSION.tar.gz

# Not 100% sure who runs the mirror above so be extra careful
if ! echo "4136d7b4c04df68b686570afa26988ac ${LIBELF_VERSION}.tar.gz" | md5sum -c -; then
    echo "Checksum failed"
    exit 1
fi

tar -xf ${LIBELF_VERSION}.tar.gz
cd $LIBELF_VERSION

# Work around a bug in the original configure not enabling __LIBELF64.
autoreconf

for arch in \
        x86_64-linux-android \
        i686-linux-android \
        aarch64-linux-android \
        arm-linux-androideabi ; do

    ccarch=${arch}
    if [ "${arch}" ==  'arm-linux-androideabi' ]
    then
       ccarch=armv7a-linux-androideabi
    fi

    export CC=/${ndk}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar
    export CC=/${ndk}/toolchains/llvm/prebuilt/linux-x86_64/bin/${ccarch}${ANDROID_SDK_VERSION}-clang
    export CXX=/${ndk}/toolchains/llvm/prebuilt/linux-x86_64/bin/${ccarch}${ANDROID_SDK_VERSION}-clang++
    export LD=/${ndk}/toolchains/llvm/prebuilt/linux-x86_64/bin/${arch}-ld
    export RANLIB=/${ndk}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib

    # The configure script doesn't know about android, but doesn't really use the host anyway it
    # seems
    ./configure --host=x86_64-linux-gnu  --disable-nls --disable-shared \
                --libdir=/usr/local/lib/${arch}
    make install
    make distclean
done

cd ..
rm -rf $LIBELF_VERSION

apt-get purge -y "${EPHEMERAL[@]}"
