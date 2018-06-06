#!/usr/bin/env bash

set -ex

# Wait for bucket to exist
attempts=60
while ! aws s3 ls --output text | grep "$bucket"; do
	sleep 10
	attempts=$(( attempts - 1 ))
	if [[ $attempts -lt 0 ]]; then
		exit 2
	fi
done

aws s3 sync s3-files/template/ "s3://${bucket}/template" --delete --exact-timestamps
aws s3 sync s3-files/inc/ "s3://${bucket}/inc" --delete --exact-timestamps
aws s3 cp s3-files/index.html "s3://${bucket}/index.html"
