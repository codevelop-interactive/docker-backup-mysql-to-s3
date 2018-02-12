#! /bin/bash

set -e

if [ "${S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi

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

if [ -z "${S3_ACCESS_KEY_ID}" ]; then
  echo "Warning: You did not set the S3_ACCESS_KEY_ID environment variable."
fi

if [ -z "${S3_SECRET_ACCESS_KEY}" ]; then
  echo "Warning: You did not set the S3_SECRET_ACCESS_KEY environment variable."
fi

if [ -z "${S3_BUCKET}" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ -z "${MYSQL_HOST}" ]; then
  echo "You need to set the MYSQL_HOST environment variable."
  exit 1
fi

if [ -z "${MYSQL_USER}" ]; then
  echo "You need to set the MYSQL_USER environment variable."
  exit 1
fi

if [ -z "${MYSQL_PASSWORD}" ]; then
  echo "You need to set the MYSQL_PASSWORD environment variable or link to a container named MYSQL."
  exit 1
fi

if [ "${S3_IAMROLE}" != "true" ]; then
  # env vars needed for aws tools - only if an IAM role is not used
  export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$S3_REGION
fi

if [ $1 = "cron" ]; then

  if [ -z "$SCHEDULE" ]; then

    echo "You need to set the SCHEDULE environment variable"
    exit 1

  fi

  if [ $2 = "backup" ]; then

    exec go-cron "$SCHEDULE" /bin/bash backup.sh

  elif [ $2 = "restore" ]; then

    exec go-cron "$SCHEDULE" /bin/bash restore.sh $3

  fi

elif [ $1 = "backup" ]; then

  ./backup.sh

elif [ $1 = "restore" ]; then

  ./restore.sh $2

fi