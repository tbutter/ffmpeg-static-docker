# ffmpeg-static-docker

static ffmpeg with the following configure options:
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
    --enable-libvidstab
    
Intended Usage:

Use it in the alpine container or copy it to your own docker build:
```
FROM tbutter/ffmpeg-static-docker:latest AS ffmpeg

FROM ubuntu
COPY --from=ffmpeg /usr/bin/ffmpeg /usr/bin/ffmpeg
```