#! /bin/bash

MYSQL_HOST_OPTS="-h $MYSQL_HOST -P $MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD"
DUMP_START_TIME=$(date +"%Y-%m-%dT%H%M%SZ")

copy_s3 () {
  SRC_FILE=$1
  DEST_FILE=$2

  if [ -z "${S3_ENDPOINT}" ]; then
    AWS_ARGS=""
  else
    AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
  fi

  echo "Uploading ${DEST_FILE} on S3..."

  cat $SRC_FILE | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/$DEST_FILE

  if [ $? != 0 ]; then
    >&2 echo "Error uploading ${DEST_FILE} on S3"
  fi

  rm $SRC_FILE
}

echo "Creating dump for ${MYSQLDUMP_DATABASE} from ${MYSQL_HOST}..."

DUMP_FILE="/tmp/dump.sql.gz"
mysqldump $MYSQL_HOST_OPTS $MYSQLDUMP_OPTIONS $MYSQLDUMP_DATABASE | gzip > $DUMP_FILE

if [ $? == 0 ]; then
  S3_FILE="${DUMP_START_TIME}.dump.sql.gz"

  copy_s3 $DUMP_FILE $S3_FILE

  _backup_tag=""
  if [ $(date +"%-m") == 1 ] && [ $(date +"%-d") == 1 ]; then
    # first day of the year
    _backup_tag="yearly"
  elif [ $(date +"%-d") == 1 ]; then
    # first day of the month
    _backup_tag="monthly"
  elif [ $(date +"%u") == 6 ]; then
    # saturday
    _backup_tag="weekly"
  else
    # any other day
    _backup_tag="daily"
  fi
  aws s3api put-object-tagging --bucket $S3_BUCKET --key $S3_PREFIX/$S3_FILE --tagging 'TagSet=[{Key=relevance,Value=${_backup_tag}}]'

else
  >&2 echo "Error creating dump of all databases"
fi

echo "SQL backup finished"
