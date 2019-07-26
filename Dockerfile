FROM ubuntu AS build

ENV CC=clang
ENV LDFLAGS="-L/work/lib -lm"
ENV CFLAGS="-I/work/include"
ENV PKG_CONFIG_PATH="/work/lib/pkgconfig"
ENV FFMPEG_VERSION="4.1.4"

RUN apt update && apt -y install wget build-essential g++ clang cmake && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*
RUN mkdir /work

ENV PATH=/work/bin:$PATH

RUN wget "http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz" && \
  tar xzvf yasm-1.3.0.tar.gz && \
  cd yasm-1.3.0 && \
  ./configure --prefix=/work && \ 
  make install

RUN wget "https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.gz" && \
  tar xzvf nasm-2.14.02.tar.gz && \
  cd nasm-2.14.02 && \
  ./configure --prefix=/work --disable-shared --enable-static && \
  make install

RUN wget -O libvpx1.8.0.tar.gz "https://github.com/webmproject/libvpx/archive/v1.8.0.tar.gz" && \
  tar xzvf libvpx1.8.0.tar.gz && \
  cd libvpx-1.8.0 && \
  ./configure --prefix=/work --disable-unit-tests --disable-shared --enable-pic && \
  make install

RUN wget "https://vorboss.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz" && \
  tar xzvf lame-3.100.tar.gz && \
	cd lame-3.100 && \
	./configure --prefix=/work --disable-shared --enable-static --with-pic && \
	make install

RUN wget "https://downloads.xvid.com/downloads/xvidcore-1.3.5.tar.gz" && \
  tar xzvf xvidcore-1.3.5.tar.gz && \
  cd xvidcore/build/generic && \
  ./configure --prefix=/work --disable-shared --enable-static && \
  make && \
  make install

RUN wget "https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-20190517-2245-stable.tar.bz2" && \
  tar xjvf x264-snapshot-20190517-2245-stable.tar.bz2 && \
  cd x264-snapshot-20190517-2245-stable && \
  ./configure --prefix=/work --enable-static --enable-pic CXXFLAGS="-fPIC" && \
  make install && \
  make install-lib-static

RUN wget "http://downloads.xiph.org/releases/ogg/libogg-1.3.3.tar.gz" && \
  tar xzvf libogg-1.3.3.tar.gz && \
  cd libogg-1.3.3 && \
  CFLAGS=-"fPIC -DPIC" ./configure --prefix=/work --disable-shared && \
  make install

RUN wget "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.6.tar.gz" && \
  tar xzvf libvorbis-1.3.6.tar.gz && \
  cd libvorbis-1.3.6 && \
	CFLAGS=-"fPIC -DPIC" ./configure --prefix=/work --with-ogg-libraries=/work/lib --with-ogg-includes=/work/include/ --enable-static --disable-shared --disable-oggtest --with-pic && \
	make install

RUN wget "http://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz" && \
  tar xzvf pkg-config-0.29.2.tar.gz && \
  cd pkg-config-0.29.2 && \
  ./configure --prefix=/work --with-pc-path=/work/lib/pkgconfig --with-internal-glib && \
  make install

RUN wget -O vid_stabv0.9.8b.tar.gz "https://github.com/georgmartius/vid.stab/archive/release-0.98b.tar.gz" && \
  tar xzvf vid_stabv0.9.8b.tar.gz && \
  cd vid.stab-release-0.98b && \
  perl -p -i -e "s/vidstab SHARED/vidstab STATIC/" CMakeLists.txt && \
  cmake -DCMAKE_INSTALL_PREFIX:PATH=/work && \
  make install

RUN wget -O av1.tar.gz "https://aomedia.googlesource.com/aom/+archive/refs/heads/master.tar.gz" && \
  mkdir av1 && cd av1 && \
  tar xzvf ../av1.tar.gz && \
  mkdir -p /aom_build && \
  cd /aom_build && \
  cmake -DENABLE_TESTS=0 -DCONFIG_PIC=1 -DCMAKE_INSTALL_PREFIX:PATH=/work /av1 && \
  make install

RUN wget "http://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2" && \
  tar xjf ffmpeg-$FFMPEG_VERSION.tar.bz2 && \
  cd ffmpeg-$FFMPEG_VERSION && \
  ./configure  \
    --pkgconfigdir="/work/lib/pkgconfig" \
    --prefix=/work \
    --pkg-config-flags="--static" \
    --extra-cflags="-I/work/include -static" \
    --extra-ldflags="-L/work/lib -static" \
    --extra-libs="-lpthread -lm" \
    --enable-static \
    --enable-pic \
    --disable-debug \
    --disable-shared \
    --disable-ffplay \
    --disable-doc \
    --enable-gpl \
    --enable-version3 \
    --enable-nonfree \
    --enable-pthreads \
    --enable-libvpx \
    --enable-libmp3lame \
    --enable-libvorbis \
    --enable-libaom \
    --enable-libx264 \
    --enable-runtime-cpudetect \
    --enable-avfilter \
    --enable-filters \
    --enable-libvidstab && \
  make install
RUN ldd /work/bin/ffmpeg || exit 0

FROM alpine
COPY --from=build /work/bin/ffmpeg /usr/bin/
COPY --from=build /work/bin/ffprobe /usr/bin/