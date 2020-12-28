#!/bin/bash

die() {
	echo FATAL: $* 1>&2
	exit 1
}

onexit() {
    if [[ $? -eq 0 ]]; then
        rm -f /tmp/backup_failed
    else
        touch /tmp/backup_failed
        if [[ -n "${BORG_FAILED_BACKUP_URL}" ]]; then
            curl -fsSL --retry 3 "${BORG_FAILED_BACKUP_URL}"
        fi
    fi
}

set -e
trap onexit EXIT

renice +19 -p $$

source /etc/backup.env

if [[ -n "${BORG_PRE_BACKUP_URL}" ]]; then
    curl -fsSL --retry 3 "${BORG_PRE_BACKUP_URL}"
fi

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
if [[ -f /etc/borg_ssh_key ]]; then
    export BORG_RSH="ssh -o StrictHostKeyChecking=accept-new -i ${BORG_KEY:-/etc/borg_ssh_key}"
fi

[[ -n "$BORG_REPO" ]] || die "BORG_REPO is not set"
[[ -n "$BORG_ARCHIVE_NAME" ]] || die "BORG_ARCHIVE_NAME is not set"
[[ -n "$BORG_PASSPHRASE" || "${BORG_ENCRYPTION}" != "repokey" ]] || die "BORG_PASSPHRASE is not set"

# TODO: Dump database snapshots

borg list :: && list_result=$? || list_result=$?
if [[ ${list_result} -eq 2 ]]; then
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

