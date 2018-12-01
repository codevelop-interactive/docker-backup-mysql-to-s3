#! /bin/bash

# exit if a command fails
set -e

# update apk
apk update

# install dependency managers
apk add python py-pip

# install mysqldump
apk add mysql-client bash

# install aws cli
pip install awscli

# cleanup
apk del py-pip
rm -rf /var/cache/apk/*
