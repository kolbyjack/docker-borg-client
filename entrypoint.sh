#!/bin/bash

set -eo pipefail

printenv | grep ^BORG_ > /etc/backup.env

exec "$@"

