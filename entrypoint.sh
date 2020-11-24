#!/bin/bash

set -eo pipefail

if [[ -f /run/secrets/borg_ssh_key ]]; then
    cp /run/secrets/borg_ssh_key /etc/borg_ssh_key
    chmod 0400 /etc/borg_ssh_key
fi

printenv | grep ^BORG_ > /etc/backup.env

echo "${BORG_SCHEDULE:-@daily} /sbin/backup.sh" >> /etc/crontabs/root

exec /usr/sbin/crond -f -d ${CROND_LOG_LEVEL:-8}

