#!/bin/bash

die() {
	echo FATAL: $* 1>&2
	exit 1
}

onexit() {
    local post_backup_url="${BORG_POST_BACKUP_URL}"

    if [[ $? -eq 0 ]]; then
        rm -f /tmp/backup_failed
    else
        echo "Backup failed!"
        touch /tmp/backup_failed
        if [[ -n "${BORG_FAILED_BACKUP_URL}" ]]; then
            post_backup_url="${BORG_FAILED_BACKUP_URL}"
        fi
    fi

    if [[ -n "${post_backup_url}" ]]; then
        echo "Calling ${post_backup_url}"
        curl -fsSL --retry 3 "${post_backup_url}"
    fi
}

set -e
trap onexit EXIT

renice +19 -p $$

source /etc/backup.env

if [[ -n "${BORG_PRE_BACKUP_URL}" ]]; then
    echo "Calling ${BORG_PRE_BACKUP_URL}"
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

if [[ -n "${BORG_MYSQL_HOST}" && -n "${BORG_MYSQL_PASSWORD}" ]]; then
    BORG_MYSQL_USER=${BORG_MYSQL_USER:-root}
    BORG_MYSQL_PATH=${BORG_MYSQL_PATH:-/backup/mysqldump}
    BORG_MYSQL_DUMP_OPTS=${BORG_MYSQL_DUMP_OPTS:---complete-insert --events --routines --triggers --single-transaction}

    if [[ -z "${BORG_MYSQL_DATABASES}" ]]; then
        BORG_MYSQL_DATABASES=$( mysql -h ${BORG_MYSQL_HOST} -u ${BORG_MYSQL_USER} "-p${BORG_MYSQL_PASSWORD}" -N -e "show databases" )
    fi

    if [[ "${BORG_MYSQL_GZIP}" != "no" ]]; then
        dump_filter="gzip"
        dump_extension=".gz"
    else
        dump_filter="cat"
        dump_extension=""
    fi

    mkdir -p "${BORG_MYSQL_PATH}"
    for db in ${BORG_MYSQL_DATABASES}; do
        if [[ "${db}" != @(information_schema|mysql|performance_schema) ]]; then
            mysqldump -h ${BORG_MYSQL_HOST} -u ${BORG_MYSQL_USER} "-p${BORG_MYSQL_PASSWORD}" ${BORG_MYSQL_DUMP_OPTS} "$db" | $dump_filter > "${BORG_MYSQL_PATH}/${db}.sql${dump_extension}"
        fi
    done
fi

echo "Checking for existing repository"
borg list :: > /dev/null 2>&1 && list_result=$? || list_result=$?
if [[ ${list_result} -eq 2 ]]; then
    borg init --encryption="${BORG_ENCRYPTION}" ::
fi

BORG_CREATE_ARGS=(-v --stats)
if [[ -n "${BORG_EXCLUDE_IF_PRESENT}" ]]; then
    BORG_CREATE_ARGS+=(--exclude-if-present "${BORG_EXCLUDE_IF_PRESENT}")
fi
BORG_CREATE_ARGS+=("::${BORG_ARCHIVE_NAME}-${NOW}")

echo "Creating new archive ${BORG_ARCHIVE_NAME}-${NOW}"
cd /backup
borg create "${BORG_CREATE_ARGS[@]}" *

if [[ -n "${BORG_PRUNE}" ]]; then
    echo "Pruning old archives"
    borg prune -v --prefix "${BORG_ARCHIVE_NAME}-" "${BORG_PRUNE[@]}"
fi

