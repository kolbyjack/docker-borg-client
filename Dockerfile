FROM alpine:latest

RUN apk --no-cache add bash borgbackup curl openssh-client

COPY backup.sh /etc/periodic/daily/
RUN chmod +x /etc/periodic/daily/backup.sh

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod +x /sbin/entrypoint.sh

ENTRYPOINT ["/sbin/entrypoint.sh", "/usr/sbin/crond", "-f"]

