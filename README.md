# docker-borg-client - A docker container to run daily borg backups

To use, mount the volumes you wish to backup under /backup, then configure the following secrets/environment variables:

|Secret|Description|
|---|---|
|`borg_ssh_key`|The private key used for remote backups|
|`borg_passphrase`|The passphrase to use with `repokey` encrypted repositories (Required when `BORG_ENCRYPTION` is `repokey`)|

Required Variables
==================
|Variable|Description|
|---|---|
|`BORG_REPO`|_none_|The target borg repository where archives will be stored|
|`BORG_ARCHIVE_NAME`|_none_|The base name to use when creating an archive|

Variables used to backup MySQL databases
========================================
|Variable|Description|
|---|---|
|`BORG_MYSQL_HOST`|_none_|The MySQL host to connect to. (Required)|
|`BORG_MYSQL_PASSWORD`|_none_|The password used to connect to MySQL. (Required)|
|`BORG_MYSQL_USER`|`root`|The user used to connect to MySQL.|
|`BORG_MYSQL_PATH`|`/backup/mysqldump`|The path where mysqldump files should be stored.|
|`BORG_MYSQL_DUMP_OPTS`|`--complete-insert --events --routines --triggers --single-transaction`|Options passed to mysqldump.|
|`BORG_MYSQL_DATABASES`|_none_|If set, the databases to dump.  If unset, all databases except `mysql`, `information_schema`, and `performance_schema` will be dumped.|
|`BORG_MYSQL_GZIP`|`yes`|If set to `no`, database dumps will not be compressed.|

Variables to control repository encryption
==========================================
|Variable|Description|
|---|---|
|`BORG_ENCRYPTION`|`repokey`|The encryption type to use (`repokey`, `keyfile`, `authenticated`)|

Variables to control archive creation and retention
===================================================
|Variable|Description|
|---|---|
|`BORG_DATEPATTERN`|`-%Y-%m-%d-%H-%M-%S`|The `date` pattern suffix to use when creating archives|
|`BORG_EXCLUDE_IF_PRESENT`|_none_|If set, exclude directories that contain the specified file|
|`BORG_KEEP_DAILY`|_none_|The number of daily backups to keep when pruning|
|`BORG_KEEP_WEEKLY`|_none_|The number of weekly backups to keep when pruning|
|`BORG_KEEP_MONTHLY`|_none_|The number of monthly backups to keep when pruning|
|`BORG_KEEP_YEARLY`|_none_|The number of yearly backups to keep when pruning|
|`BORG_KEEP_WITHIN`|_none_|Keep all archives within this time interval|

Variables to control reporting
==============================
|Variable|Description|
|---|---|
|`BORG_FAILED_BACKUP_URL`|_none_|If set, a url to request when the backup fails|
|`BORG_POST_BACKUP_URL`|_none_|If set, a url to request when the backup is complete|
|`BORG_PRE_BACKUP_URL`|_none_|If set, a url to request when the backup script begins|

System Variables
================
|Variable|Description|
|---|---|
|`BORG_REMOTE_PATH`|_none_|If set, the path to the borg executable on the server|

Cron Variables
==============
|Variable|Description|
|---|---|
|`BORG_SCHEDULE`|`@daily`|A cron schedule expression to determine when to run the backup|
|`CROND_LOG_LEVEL`|`8`|The log level to use for crond in the container|
