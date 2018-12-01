#! /bin/bash

set -e

if [ "${S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi


if [ "${CRON_SCHEDULE}" = "" ]; then
  sh backup.sh
else
  echo "Setting up cron: ${CRON_SCHEDULE}"

  rm -f /etc/cron.d/root

  mkdir -p /etc/cron.d

  touch /var/log/cron.log

  printf "SHELL=/bin/bash\n# min hour day month weekday command\n${CRON_SCHEDULE} /backup.sh >> /var/log/cron.log 2>&1\n# An empty line is required at the end of this file for a valid cron file." >> /etc/cron.d/root

  /usr/sbin/crond -S -l 0 -c /etc/cron.d

  echo "Cron is running"

  tail -f /var/log/cron.log
fi