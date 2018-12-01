FROM alpine:latest
LABEL maintainer="Steven McCoy <steven@codevelop.ca>"
ADD install.sh install.sh
RUN sh install.sh && rm install.sh
ENV MYSQLDUMP_OPTIONS --quote-names --quick --add-drop-table --add-locks --allow-keywords --disable-keys --extended-insert --single-transaction --create-options --comments --net_buffer_length=16384
ENV MYSQLDUMP_DATABASE --all-databases
ENV MYSQL_HOST=
ENV MYSQL_PORT=3306
ENV MYSQL_USER=
ENV MYSQL_PASSWORD=
ENV S3_ACCESS_KEY_ID=
ENV S3_SECRET_ACCESS_KEY=
ENV S3_BUCKET=
ENV S3_REGION us-west-1
ENV S3_ENDPOINT=
ENV S3_S3V4=no
ENV S3_PREFIX='backup'
ENV CRON_SCHEDULE=

ADD run.sh /run.sh
ADD backup.sh /backup.sh
ADD restore.sh /restore.sh
WORKDIR /
ENTRYPOINT ["/run.sh"]

CMD ["backup"]