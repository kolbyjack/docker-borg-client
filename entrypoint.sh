#!/bin/bash

set -eo pipefail

if [[ -f /run/secrets/borg_ssh_key ]]; then
    cp /run/secrets/borg_ssh_key /etc/borg_ssh_key
    chmod 0400 /etc/borg_ssh_key
fi

printenv | grep ^BORG_ > /etc/backup.env

exec "$@"

