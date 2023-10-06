# ffmpeg - http://ffmpeg.org/download.html
#
# From https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
#
# https://hub.docker.com/r/jrottenberg/ffmpeg/
#
#

FROM    nvidia/cuda:12.2.0-devel-ubuntu20.04 AS nvidia-base

ENV	    NVIDIA_DRIVER_CAPABILITIES compute,utility,video
ENV	    DEBIAN_FRONTEND=nonintercative
WORKDIR     /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 && \
        apt-get autoremove -y && \
        apt-get clean -y

RUN mkdir -p /usr/local/src/cuda-12.2/lib64 && find "/usr/local/cuda-12.2/lib64/" -depth -iname "*libnpp*.so.11" -exec cp {} /usr/local/src/cuda-12.2/lib64/ \;


FROM golang:bullseye AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -buildvcs=false -ldflags="-s -w"

FROM ubuntu:22.04
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y \
    sudo curl wget xz-utils

RUN mkdir -p /opt/ffmpeg \
    && cd /opt/ffmpeg \
    && owner_repo='jellyfin/jellyfin-ffmpeg'; latest_version_url="$(curl -s https://api.github.com/repos/$owner_repo/releases/latest | grep "browser_download_url.*linux64-gpl.tar.xz" | cut -d : -f 2,3 | tr -d \")"; echo $latest_version_url; basename $latest_version_url ; wget --content-disposition $latest_version_url \
    && tar -xvf *linux64-gpl.tar.xz \
    && cd / \
    && ln -s /opt/ffmpeg/ffmpeg /usr/bin \
    && ln -s /opt/ffmpeg/ffprobe /usr/bin


COPY --from=builder /app/go-vod .

COPY --from=nvidia-base /usr/local/bin /usr/local/bin/
COPY --from=nvidia-base /usr/local/share /usr/local/share/
COPY --from=nvidia-base /usr/local/lib /usr/local/lib/
COPY --from=nvidia-base /usr/local/include /usr/local/include/
COPY --from=nvidia-base /usr/local/cuda/include/ /usr/local/cuda/include/
COPY --from=nvidia-base /usr/local/cuda/lib64/ /usr/local/cuda/lib64/
EXPOSE 47788
CMD ["/app/go-vod"]
