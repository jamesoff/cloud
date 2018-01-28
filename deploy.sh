#!/usr/bin/env bash

set -e

echo Uploading template
aws s3 sync template/ s3://cloud.jamesoff.net/template --delete --exact-timestamps

echo Preparing lambda
[ -f lambda.zip ] && rm lambda.zip
(
cd lambda
zip -r ../lambda.zip ./*
)

echo Deploying lambda
aws lambda update-function-code --function-name cloud-handler --zip-file fileb://lambda.zip
