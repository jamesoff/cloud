#!/usr/bin/env bash

set -ex

# Hello! If you're not me, you probably want deploy.sh
# This script is for me to update the location used by the CF deployment to get
# code into Lambda

[ -f lambda.zip ] && rm lambda.zip
(
cd lambda
pip install -r requirements.txt -t .
zip -q -r ../lambda.zip ./*
)

aws s3 cp lambda.zip s3://code.jamesoff.net/cloud/lambda.zip
