#! /bin/bash

# exit if a command fails
set -e


apk update

# install mysqldump
apk add mysql-client bash

# install s3 tools
apk add python py-pip
pip install awscli
apk del py-pip

# cleanup
rm -rf /var/cache/apk/*