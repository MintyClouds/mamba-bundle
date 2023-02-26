FROM nextcloud:25.0.4-apache

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install git nano -y
RUN apt-get -y install software-properties-common -y
RUN apt-get -y install ffmpeg -y
RUN apt-get -y install exiftool -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
