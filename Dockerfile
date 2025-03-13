# syntax=docker/dockerfile:1

# FROM mojrapid/baseimage:ubuntu_jammy_s6_plex
FROM mojrapid/baseimage:ubuntu-jammy_s6_full

# set version label
ARG BUILD_DATE
ARG VERSION
ARG SONARR_VERSION
LABEL build_version="mojrapid:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL name="Sonarr: ${SONARR_VERSION}"
LABEL maintainer="mojrapid"
LABEL org.opencontainers.image.version=${VERSION}
LABEL org.opencontainers.image.created=${BUILD_DATE}
LABEL org.opencontainers.image.authors="mojrapid"

# set environment variables
ENV XDG_CONFIG_HOME="/config/xdg"
ENV SONARR_BRANCH="main"
ENV SONARR_CHANNEL="v4-stable"

RUN \
  echo "**** install packages ****" && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    mediainfo \
    sqlite3 \
    xmlstarlet && \
  echo "**** install sonarr ****" && \
  mkdir -p /app/sonarr/bin && \
  if [ -z ${SONARR_VERSION+x} ]; then \
    SONARR_VERSION=$(curl -sX GET http://services.sonarr.tv/v1/releases \
    | jq -r "first(.[] | select(.releaseChannel==\"${SONARR_CHANNEL}\") | .version)"); \
  fi && \
  curl -o \
    /tmp/sonarr.tar.gz -L \
    "https://services.sonarr.tv/v1/update/${SONARR_BRANCH}/download?version=${SONARR_VERSION}&os=linux&runtime=netcore&arch=arm" && \
  tar xzf \
    /tmp/sonarr.tar.gz -C \
    /app/sonarr/bin --strip-components=1 && \
  echo -e "UpdateMethod=docker\nBranch=${SONARR_BRANCH}\nPackageVersion=${VERSION}\nPackageAuthor=[mojrapid](https://)" > /app/sonarr/package_info && \
  echo "**** cleanup ****" && \
  rm -rf \
    /app/sonarr/bin/Sonarr.Update \
    /tmp/* \
    /var/lib/aptlists/* \
    /var/tmp/*

RUN \
 apt-get clean -y \
 apt-get autoclean -y \
 apt-get autoremove -y

# add local files
COPY root/ /

# ports and volumes
EXPOSE 8989

VOLUME /config
