#!/usr/bin/env bash

set -ex


[ -f lambda.zip ] && rm lambda.zip
(
cd lambda
pip install -r requirements.txt -t .
zip -q -r ../lambda.zip ./*
)

aws s3 cp lambda.zip s3://code.jamesoff.net/cloud/lambda.zip
