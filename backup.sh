#!/bin/bash

die() {
	echo FATAL: $* 1>&2
	exit 1
}

set -e

renice +19 -p $$

source /etc/backup.env

BORG_ENCRYPTION=${BORG_ENCRYPTION:-repokey}
BORG_DATEPATTERN=${BORG_DATEPATTERN:-%Y-%m-%d-%H-%M-%S}

if [[ -f /run/secrets/borg_passphrase ]]; then
    export BORG_PASSPHRASE=$( cat /run/secrets/borg_passphrase | xargs echo -n )
fi

BORG_PRUNE=()
[[ -n "$BORG_KEEP_DAILY" ]] && BORG_PRUNE+=(--keep-daily "$BORG_KEEP_DAILY")
[[ -n "$BORG_KEEP_WEEKLY" ]] && BORG_PRUNE+=(--keep-weekly "$BORG_KEEP_WEEKLY")
[[ -n "$BORG_KEEP_MONTHLY" ]] && BORG_PRUNE+=(--keep-monthly "$BORG_KEEP_MONTHLY")
[[ -n "$BORG_KEEP_YEARLY" ]] && BORG_PRUNE+=(--keep-yearly "$BORG_KEEP_YEARLY")
[[ -n "$BORG_KEEP_WITHIN" ]] && BORG_PRUNE+=(--keep-within "$BORG_KEEP_WITHIN")

NOW=$( date "+${BORG_DATEPATTERN}" )
if [[ ${BORG_REPO[0]} != "/" ]]; then
    export BORG_RSH="ssh -o StrictHostKeyChecking=accept-new -i ${BORG_KEY:-/run/secrets/borg_ssh_key}"
fi

[[ -n "$BORG_REPO" ]] || die "BORG_REPO is not set"
[[ -n "$BORG_ARCHIVE_NAME" ]] || die "BORG_ARCHIVE_NAME is not set"
[[ -n "$BORG_PASSPHRASE" || "${BORG_ENCRYPTION}" != "repokey" ]] || die "BORG_PASSPHRASE is not set"

# TODO: Dump database snapshots

borg list ::
if [[ "$?" == "2" ]]; then
    borg init --encryption="${BORG_ENCRYPTION}" ::
fi

BORG_CREATE_ARGS=(-v --stats "::${BORG_ARCHIVE_NAME}-${NOW}" /backup)
if [[ -n "${BORG_EXCLUDE_IF_PRESENT}" ]]; then
    BORG_CREATE_ARGS+=(--exclude-if-present "${BORG_EXCLUDE_IF_PRESENT}")
fi

borg create "${BORG_CREATE_ARGS[@]}"

if [[ -n "${BORG_PRUNE}" ]]; then
    borg prune -v --prefix "${BORG_ARCHIVE_NAME}-" "${BORG_PRUNE[@]}"
fi

if [[ -n "${BORG_POST_BACKUP_URL}" ]]; then
    curl -fsSL --retry 3 "${BORG_POST_BACKUP_URL}"
fi

