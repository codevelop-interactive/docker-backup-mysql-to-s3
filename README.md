# mysql-s3

Backup and Restore MySQL databases to S3 (supports periodic backups)

## Environment variables

- `MYSQLDUMP_OPTIONS` mysqldump options (default: --quote-names --quick --add-drop-table --add-locks --allow-keywords --disable-keys --extended-insert --single-transaction --create-options --comments --net_buffer_length=16384)
- `MYSQLDUMP_DATABASE` list of databases you want to backup (default: --all-databases)
- `MYSQL_HOST` the mysql host *required*
- `MYSQL_PORT` the mysql port (default: 3306)
- `MYSQL_USER` the mysql user *required*
- `MYSQL_PASSWORD` the mysql password *required*
- `S3_ACCESS_KEY_ID` your AWS access key *required*
- `S3_SECRET_ACCESS_KEY` your AWS secret key *required*
- `S3_BUCKET` your AWS S3 bucket path *required*
- `S3_PREFIX` path prefix in your bucket (default: 'backup')
- `S3_REGION` the AWS S3 bucket region (default: us-west-1)
- `S3_ENDPOINT` the AWS Endpoint URL, for S3 Compliant APIs such as [minio](https://minio.io) (default: none)
- `S3_S3V4` set to `yes` to enable AWS Signature Version 4, required for [minio](https://minio.io) servers (default: no)
- `SCHEDULE` backup schedule time, see explainatons below

## Secrets

You can alternatively mount docker secrets and configure their location using the following environment variables

- `S3_ACCESS_KEY_ID_FILE` your path to the AWS access key secret file
- `S3_SECRET_ACCESS_KEY_FILE` your path to the AWS secret key file
- `MYSQL_PASSWORD_FILE` your path to the mysql password secret file

## Commands

- `backup` runs a one-off backup to the S3 bucket
- `cron backup` runs scheduled backups to the S3 bucket as defined by the `SCHEDULE` environment variable
- `restore` runs a one-off restore from the latest backup in the S3 bucket
- `restore backupfile.dump.sql.gz` runs a one-off restore from the specified backup in the S3 bucket
- `restore cron ` runs scheduled restores from the latest backup in the S3 bucket
- `restore cron backupfile.dump.sql.gz` runs scheduled restores from the specified backup in the S3 bucket

You can additionally set the `SCHEDULE` environment variable like `-e SCHEDULE="@daily"` to run the backup automatically.

Learn more about valid values for the `SCHEDULE` environment variable [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules).
