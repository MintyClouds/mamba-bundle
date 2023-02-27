# ffmpeg - http://ffmpeg.org/download.html
#
# From https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
#
# https://hub.docker.com/r/jrottenberg/ffmpeg/
#
#

FROM    nvidia/cuda:11.4.1-devel-ubuntu20.04 AS devel-base

ENV	    NVIDIA_DRIVER_CAPABILITIES compute,utility,video
ENV	    DEBIAN_FRONTEND=nonintercative
WORKDIR     /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 && \
        apt-get autoremove -y && \
        apt-get clean -y

FROM        nextcloud:25.0.4-apache AS runtime-base

ENV	    NVIDIA_DRIVER_CAPABILITIES compute,utility,video
ENV	    DEBIAN_FRONTEND=nonintercative
WORKDIR     /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 libxcb-shape0-dev exiftool && \
        apt-get autoremove -y && \
        apt-get clean -y


FROM  devel-base as build

RUN      buildDeps="build-essential \
                    automake \
                    cmake \
                    curl \
                    wget \
                    libc6 \
                    libc6-dev \
                    unzip \
                    libnuma1 \
                    libnuma-dev \
                    bzip2 \
                    libexpat1-dev \
                    g++ \
                    gcc \
                    git \
                    gperf \
                    libtool \
                    make \
                    nasm \
                    perl \
                    pkg-config \
                    python \
                    libssl-dev \
                    yasm \
                    git \
                    zlib1g-dev" && \
        apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ${buildDeps}

RUN \
	DIR=/tmp/nv-codec-headers && \
	git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git ${DIR} && \
	cd ${DIR} && \
	make && \
	make install && \
    rm -rf ${DIR}


## Download ffmpeg https://ffmpeg.org/
RUN \
    DIR=/tmp/ffmpeg && \
    git clone https://git.ffmpeg.org/ffmpeg.git ${DIR} 


## Build ffmpeg https://ffmpeg.org/
RUN  \
        DIR=/tmp/ffmpeg && cd ${DIR} && \
        ./configure \
        --enable-nonfree \
        --enable-cuda-nvcc \
        --enable-libnpp \
        --extra-cflags=-I/usr/local/cuda/include \
        --extra-ldflags=-L/usr/local/cuda/lib64 \
        --disable-static \
        --enable-shared && \
        make -j 4 && \
        make install 

RUN \
        LD_LIBRARY_PATH="${PREFIX}/lib:${PREFIX}/lib64:${LD_LIBRARY_PATH}" ldd ${PREFIX}/bin/ffmpeg | grep opt/ffmpeg | cut -d ' ' -f 3 | xargs -i cp {} /usr/local/lib/ && \
        for lib in /usr/local/lib/*.so.*; do ln -s "${lib##*/}" "${lib%%.so.*}".so; done && \
        cp ${PREFIX}/bin/* /usr/local/bin/ && \
        cp -r ${PREFIX}/share/* /usr/local/share/ && \
        LD_LIBRARY_PATH=/usr/local/lib ffmpeg -buildconf && \
        cp -r ${PREFIX}/include/libav* ${PREFIX}/include/libpostproc ${PREFIX}/include/libsw* /usr/local/include && \
        mkdir -p /usr/local/lib/pkgconfig && \
        for pc in ${PREFIX}/lib/pkgconfig/libav*.pc ${PREFIX}/lib/pkgconfig/libpostproc.pc ${PREFIX}/lib/pkgconfig/libsw*.pc; do \
          sed "s:${PREFIX}:/usr/local:g; s:/lib64:/lib:g" <"$pc" >/usr/local/lib/pkgconfig/"${pc##*/}"; \
        done
RUN mkdir -p /usr/local/src/cuda-11.4/lib64 && find "/usr/local/cuda-11.4/lib64/" -depth -iname "*libnpp*.so.11" -exec cp {} /usr/local/src/cuda-11.4/lib64/ \;
    

FROM        runtime-base AS release
# ENV         LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64

WORKDIR     /var/www/html

# copy only needed files, without copying nvidia dev files
COPY --from=build /usr/local/bin /usr/local/bin/
COPY --from=build /usr/local/share /usr/local/share/
COPY --from=build /usr/local/lib /usr/local/lib/
COPY --from=build /usr/local/include /usr/local/include/

# RUN     apt-get install -yq software-properties-common
# RUN     add-apt-repository contrib
# RUN     apt-get -yqq update && \
#         apt-get install -yq wget
#
# RUN     wget -P /tmp/ https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/cuda-keyring_1.0-1_all.deb
# RUN     dpkg -i /tmp/cuda-keyring_1.0-1_all.deb
# RUN     echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/ /" | tee /etc/apt/sources.list.d/cuda-debian11-x86_64.list                                                                          
#
# RUN     apt-get -yqq update && \
#         apt-get install -yq cuda
#
# RUN     apt-get autoremove -y && \
#         apt-get clean -y
# RUN     rm -rf /usr/bin/nvidia*

#COPY ./lib/ /usr/local/lib

# Let's make sure the app built correctly
# Convenient to verify on https://hub.docker.com/r/jrottenberg/ffmpeg/builds/ console output

