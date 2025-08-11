FROM ubuntu:24.04

# Install build dependencies
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    build-essential \
    cmake \
    git \
    libass-dev \
    libfreetype6-dev \
    libgnutls28-dev \
    libmp3lame-dev \
    libopus-dev \
    libtheora-dev \
    libtool \
    libvorbis-dev \
    libvpx-dev \
    libx264-dev \
    libx265-dev \
    mercurial \
    pkg-config \
    texinfo \
    wget \
    yasm \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone and build x265 (required for HEVC encoding)
RUN hg clone https://bitbucket.org/multicoreware/x265 /tmp/x265 \
    && cd /tmp/x265/build/linux \
    && cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_SHARED:bool=off ../../source \
    && make \
    && make install

# Clone FFmpeg source from the repo (since we're in the repo context, but for safety, clone it)
RUN git clone https://github.com/FFmpeg/FFmpeg.git /ffmpeg \
    && cd /ffmpeg \
    && ./configure \
        --prefix=/usr/local \
        --pkg-config-flags="--static" \
        --extra-cflags="-I/usr/local/include" \
        --extra-ldflags="-L/usr/local/lib" \
        --extra-libs="-lpthread -lm" \
        --enable-gpl \
        --enable-gnutls \
        --enable-libass \
        --enable-libfreetype \
        --enable-libmp3lame \
        --enable-libopus \
        --enable-libtheora \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libx264 \
        --enable-libx265 \
        --enable-nonfree \
    && make -j$(nproc) \
    && make install

# Set the entrypoint to run FFmpeg commands
ENV PATH="/usr/local/bin:${PATH}"
CMD ["ffmpeg", "-version"]
