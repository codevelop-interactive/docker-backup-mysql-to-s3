#! /bin/bash

MYSQL_HOST_OPTS="-h $MYSQL_HOST -P $MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD"

BUCKET_EXIST=$(aws s3 --region ${S3_REGION} ls | grep ${S3_BUCKET} | wc -l)

if [ ${BUCKET_EXIST} -eq 0 ]; then
  echo "Bucket Doesn't Exist"
  exit 1
fi


if [ -z "$1" ]; then
# Find last backup file
: ${LAST_BACKUP:=$(aws s3 ls s3://$S3_BUCKET/$S3_PREFIX/ | awk -F " " '{print $4}' | sort -r | head -n1)}
fi

if [ -z "$LAST_BACKUP" ]; then

  echo "No backup found"
  exit 1

fi

S3_BACKUP_PATH="s3://${S3_BUCKET}/${S3_PREFIX}/${LAST_BACKUP}"

echo "Downloading backup from ${S3_BACKUP_PATH}"

DUMP_FILE="/tmp/dump.sql.gz"

aws s3 cp $S3_BACKUP_PATH $DUMP_FILE

echo "Restoring backup"

if zcat $DUMP_FILE | mysql $MYSQL_HOST_OPTS ;then

  echo "Restore complete"

else

  echo "Restore failed"

fi