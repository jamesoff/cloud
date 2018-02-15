#!/usr/bin/env bash

cloud_config=${CLOUD_CONFIG:-"config"}

[[ -f "$HOME/.config/cloud/$cloud_config" ]] && source "$HOME/.config/cloud/$cloud_config"

cloud_bucket=${CLOUD_BUCKET?"Missing CLOUD_BUCKET config"}
cloud_domain=${CLOUD_DOMAIN?"Missing CLOUD_DOMAIN config"}
cloud_queue=${CLOUD_QUEUE?"Missing CLOUD_QUEUE config"}
cloud_profile=${CLOUD_PROFILE?"Missing CLOUD_PROFILE config"}

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

if ! aws s3 cp "$file" "s3://$cloud_bucket/assets/$filename" --profile "$cloud_profile" > /dev/null; then
	echoerr "Upload failed!"
	exit 1
fi

message_json=""
attempts=0
while [[ $attempts -lt 6 ]]; do
	attempts=$(( attempts + 1 ))
	message_json=$( aws sqs receive-message \
		--wait-time-seconds 10 \
		--queue-url "$cloud_queue" \
		--profile "$cloud_profile"
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

cloud_path=$( echo "$body" | cut -d= -f2 | tr -d ' ' )
echo -n "https://$cloud_domain/$cloud_path"

aws sqs delete-message \
	--queue-url "$cloud_queue" \
	--receipt-handle "$handle" \
	--profile "$cloud_profile"
