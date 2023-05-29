FROM ubuntu:focal as builder

ENV TZ=UTC

ADD https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz /ffmpeg-master-latest-linux64-gpl.tar.xz

RUN apt-get update && apt-get upgrade -y && apt-get install -y xz-utils && \
    tar -xf /ffmpeg-master-latest-linux64-gpl.tar.xz && \
    rm /ffmpeg-master-latest-linux64-gpl.tar.xz 


FROM ubuntu:focal

ENV TZ=UTC

ENV PUID=1000
ENV PGID=1000

# Install yt-dlp
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get upgrade -y && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y \
    ca-certificates \
    python3 \
    python3-pip \
    ffmpeg \
    atomicparsley \
    phantomjs && \
    python3 -m pip install --upgrade yt-dlp mutagen certifi brotli websockets && \
    rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/*

COPY --from=builder /ffmpeg-master-latest-linux64-gpl/bin/ffmpeg /usr/bin/ffmpeg
COPY --from=builder /ffmpeg-master-latest-linux64-gpl/bin/ffplay /usr/bin/ffplay
COPY --from=builder /ffmpeg-master-latest-linux64-gpl/bin/ffprobe /usr/bin/ffprobe

# make it run as user 
RUN mkdir /download && \
    mkdir /cache && \
    mkdir -p /home/ytdlp && \
    groupadd -g ${PGID} ytdlp && \
    useradd -u ${PUID} -g ${PGID} ytdlp && \
    chown -R ${PUID}:${PGID} /download && \
    chown -R ${PUID}:${PGID} /cache && \
    chown -R ${PUID}:${PGID} /home/ytdlp

WORKDIR /download

USER ytdlp

ENTRYPOINT [ "yt-dlp" ]
