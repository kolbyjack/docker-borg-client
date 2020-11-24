FROM alpine:latest

RUN apk --no-cache add bash borgbackup curl openssh-client

COPY backup.sh /sbin/backup.sh
RUN chmod +x /sbin/backup.sh

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

ENTRYPOINT ["/sbin/entrypoint.sh"]

HEALTHCHECK CMD test ! -f /tmp/backup_failed

