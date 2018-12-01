#! /bin/bash

set -e

file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
          echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
          exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
          val="${!var}"
  elif [ "${!fileVar:-}" ]; then
          val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

file_env 'MYSQL_PASSWORD' ''
file_env 'S3_ACCESS_KEY_ID' ''
file_env 'S3_SECRET_ACCESS_KEY' ''


if [ "${S3_ACCESS_KEY_ID}" == "" ]; then
  echo "Warning: You did not set the S3_ACCESS_KEY_ID environment variable."
fi

if [ "${S3_SECRET_ACCESS_KEY}" == "" ]; then
  echo "Warning: You did not set the S3_SECRET_ACCESS_KEY environment variable."
fi

if [ "${S3_BUCKET}" == "" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${MYSQL_HOST}" == "" ]; then
  echo "You need to set the MYSQL_HOST environment variable."
  exit 1
fi

if [ "${MYSQL_USER}" == "" ]; then
  echo "You need to set the MYSQL_USER environment variable."
  exit 1
fi

if [ "${MYSQL_PASSWORD}" == "" ]; then
  echo "You need to set the MYSQL_PASSWORD environment variable or link to a container named MYSQL."
  exit 1
fi

if [ "${S3_IAMROLE}" != "true" ]; then
  # env vars needed for aws tools - only if an IAM role is not used
  export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$S3_REGION
fi

MYSQL_HOST_OPTS="-h $MYSQL_HOST -P $MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD"
DUMP_START_TIME=$(date +"%Y-%m-%dT%H%M%SZ")

copy_s3 () {
  SRC_FILE=$1
  DEST_FILE=$2

  if [ "${S3_ENDPOINT}" == "" ]; then
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

   aws s3api put-object-tagging --bucket $S3_BUCKET --key $S3_PREFIX/$DEST_FILE --tagging 'TagSet=[{Key=relevance,Value='${_backup_tag}'}]'
}

# Multi file: yes
if [ ! -z "$(echo $MULTI_FILES | grep -i -E "(yes|true|1)")" ]; then
  if [ "${MYSQLDUMP_DATABASE}" == "--all-databases" ]; then
    DATABASES=`mysql $MYSQL_HOST_OPTS -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys|innodb)"`
  else
    DATABASES=$MYSQLDUMP_DATABASE
  fi

  for DB in $DATABASES; do
    echo "Creating individual dump of ${DB} from ${MYSQL_HOST}..."

    DUMP_FILE="/tmp/${DB}.sql.gz"

    mysqldump $MYSQL_HOST_OPTS $MYSQLDUMP_OPTIONS --databases $DB | gzip > $DUMP_FILE

    if [ $? == 0 ]; then
      S3_FILE="${DUMP_START_TIME}.${DB}.sql.gz"

      copy_s3 $DUMP_FILE $S3_FILE
    else
      >&2 echo "Error creating dump of ${DB}"
    fi
  done
# Multi file: no
else
  echo "Creating dump for ${MYSQLDUMP_DATABASE} from ${MYSQL_HOST}..."

  DUMP_FILE="/tmp/dump.sql.gz"
  mysqldump $MYSQL_HOST_OPTS $MYSQLDUMP_OPTIONS $MYSQLDUMP_DATABASE | gzip > $DUMP_FILE

  if [ $? == 0 ]; then
    S3_FILE="${DUMP_START_TIME}.dump.sql.gz"

    copy_s3 $DUMP_FILE $S3_FILE
  else
    >&2 echo "Error creating dump of all databases"
  fi
fi