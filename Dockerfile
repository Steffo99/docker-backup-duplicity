# FROM archlinux:latest
FROM alpine:latest AS final

# Install duplicity
# RUN pacman --noconfirm -Syu duplicity python-pip python-pydrive2
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true
RUN apk add py3-pip python3-dev gcc libffi-dev musl-dev openssl-dev pkgconfig duplicity rust cargo git curl
RUN pip install --upgrade pip --break-system-packages
RUN pip install google-auth-oauthlib google-api-python-client --break-system-packages
RUN apk del rust musl-dev libffi-dev gcc python3-dev cargo git pkgconfig openssl-dev

# Create log directory
RUN mkdir --parents --verbose /var/log/duplicity

# Create program directory
WORKDIR /usr/lib/duplicity
ENV HOME="/usr/lib/duplicity"

# Add entrypoint
COPY ./entrypoint.sh /usr/lib/backup-duplicity/entrypoint.sh
COPY ./restore.sh /usr/lib/backup-duplicity/restore.sh
COPY ./backup.sh /etc/periodic/daily/backup.sh

# Configure entrypoint and command
ENTRYPOINT ["/usr/lib/backup-duplicity/entrypoint.sh"]
CMD []

# Add image labels
LABEL org.opencontainers.image.title="backup-duplicity"
LABEL org.opencontainers.image.description="Backup solution for Docker volumes based on Duplicity"
LABEL org.opencontainers.image.licenses="AGPL-3.0-or-later"
LABEL org.opencontainers.image.url="https://github.com/Steffo99/docker-backup-duplicity"
LABEL org.opencontainers.image.authors="Stefano Pigozzi <me@steffo.eu>"

# Configure duplicity
ENV DUPLICITY_FULL_IF_OLDER_THAN=1M

ENV NTFY=""
ENV NTFY_TAGS=""
