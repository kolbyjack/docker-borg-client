# docker-borg-client - A docker container to run daily borg backups

To use, mount the volumes you wish to backup under /backup, then configure the following secrets/environment variables:

|Secret|Description|
|---|---|
|`borg_ssh_key`|The private key used for remote backups|
|`borg_passphrase`|The passphrase to use with `repokey` encrypted repositories (Required when `BORG_ENCRYPTION` is `repokey`)|

|Variable|Default|Description|
|---|---|---|
|`BORG_REPO`|_none_|The target borg repository where archives will be stored (Required)|
|`BORG_ARCHIVE_NAME`|_none_|The base name to use when creating an archive (Required)|
|`BORG_DATEPATTERN`|`-%Y-%m-%d-%H-%M-%S`|The `date` pattern suffix to use when creating archives|
|`BORG_ENCRYPTION`|`repokey`|The encryption type to use (`repokey`, `keyfile`, `authenticated`)|
|`BORG_EXCLUDE_IF_PRESENT`|_none_|If set, exclude directories that contain the specified file|
|`BORG_KEEP_DAILY`|_none_|The number of daily backups to keep when pruning|
|`BORG_KEEP_WEEKLY`|_none_|The number of weekly backups to keep when pruning|
|`BORG_KEEP_MONTHLY`|_none_|The number of monthly backups to keep when pruning|
|`BORG_KEEP_YEARLY`|_none_|The number of yearly backups to keep when pruning|
|`BORG_KEEP_WITHIN`|_none_|Keep all archives within this time interval|
|`BORG_FAILED_BACKUP_URL`|_none_|If set, a url to request when the backup fails|
|`BORG_POST_BACKUP_URL`|_none_|If set, a url to request when the backup is complete|
|`BORG_PRE_BACKUP_URL`|_none_|If set, a url to request when the backup script begins|
|`BORG_REMOTE_PATH`|_none_|If set, the path to the borg executable on the server|
|`BORG_SCHEDULE`|`@daily`|A cron schedule expression to determine when to run the backup|
|`CROND_LOG_LEVEL`|`8`|The log level to use for crond in the container|
