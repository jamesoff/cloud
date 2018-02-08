#!/usr/bin/env bash

cloud_bucket=${CLOUD_BUCKET:-"cloud.jamesoff.net"}
cloud_domain=${CLOUD_DOMAIN:-"cloud.jamesoff.net"}
cloud_queue=${CLOUD_QUEUE:-"https://sqs.eu-west-1.amazonaws.com/108685319098/cloud-output"}

echoerr() {
	echo "$@" 1>&2
}

usage() {
	echoerr "usage: $0 PATH"
	echoerr ""
	echoerr "Host an image in the cloud"
	exit 1
}

if [[ $# == 0 ]]; then
	usage
fi

if ! hash jq 2>/dev/null; then
	echoerr "Needs more jq."
	exit 1
fi

file=$1

if [[ ! -r $file ]]; then
	echoerr "File $file does not exist or is not readable."
	exit 1
fi

filename=$(basename "$file")

if ! aws s3 cp "$file" "s3://$cloud_bucket/assets/$filename" > /dev/null; then
	echoerr "Upload failed!"
	exit 1
fi

message_json=""
attempts=0
while [[ $attempts -lt 6 ]]; do
	attempts=$(( attempts + 1 ))
	message_json=$( aws sqs receive-message \
		--wait-time-seconds 10 \
		--queue-url "$cloud_queue"
	)

	if [[ -z $message_json ]]; then
		echoerr "Failed to receive message with image information. Retrying..."
		continue
	fi

	body=$( echo "$message_json" | jq -r '.Messages[].Body' )
	handle=$( echo "$message_json" | jq -r '.Messages[].ReceiptHandle' )

	if [[ $body =~ ^$filename= ]]; then
		break
	else
		echoerr "Received a message but it wasn't for us!"
		body=""
		continue
	fi
done

if [[ -z "$body" ]]; then
	echoerr "Failed to fetch URL."
	exit 1
fi

cloud_path=$( echo "$body" | cut -d= -f2 )
echo -n "https://$cloud_domain/$cloud_path"

aws sqs delete-message \
	--queue-url "$cloud_queue" \
	--receipt-handle "$handle"
