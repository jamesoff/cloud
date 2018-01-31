#!/usr/bin/env bash

set -e

echo Uploading template and assets
aws s3 sync s3-files/template/ s3://cloud.jamesoff.net/template --delete --exact-timestamps
aws s3 sync s3-files/inc/ s3://cloud.jamesoff.net/inc --delete --exact-timestamps

if [[ $1 == "lambda" ]]; then
	echo Preparing lambda
	[ -f lambda.zip ] && rm lambda.zip
	(
	cd lambda
	zip -q -r ../lambda.zip ./*
	)

	echo Deploying lambda
	aws lambda update-function-code --function-name cloud-handler --zip-file fileb://lambda.zip
fi
