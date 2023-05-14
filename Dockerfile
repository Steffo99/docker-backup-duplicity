# FROM archlinux:latest
FROM alpine:latest AS base

# Install duplicity
# RUN pacman --noconfirm -Syu duplicity python-pip python-pydrive2
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true
RUN \
  apk add py3-pip python3-dev gcc libffi-dev musl-dev openssl-dev pkgconfig duplicity rust cargo git && \
  pip install --upgrade pip && \
  pip install pydrive2 && \
  apk del rust musl-dev libffi-dev gcc python3-dev cargo git pkgconfig openssl-dev

WORKDIR /var/lib/duplicity
ENV HOME="/var/lib/duplicity"

# Configure entrypoint and command
ENTRYPOINT ["crond", "-f", "-d", "5"]
CMD []

# Add image labels
LABEL org.opencontainers.image.title="backup-duplicity"
LABEL org.opencontainers.image.description="Backup solution for Docker volumes based on Duplicity"
LABEL org.opencontainers.image.licenses="AGPL-3.0-or-later"
LABEL org.opencontainers.image.url="https://github.com/Steffo99/docker-backup-duplicity"
LABEL org.opencontainers.image.authors="Stefano Pigozzi <me@steffo.eu>"

# Add duplicity to cron
COPY ./backup.sh /etc/periodic/daily/backup.sh

# Configure duplicity
ENV DUPLICITY_FULL_IF_OLDER_THAN=1M

