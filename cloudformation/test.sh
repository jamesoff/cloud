#!/usr/bin/env bash

set -e

echoerr() {
	echo "$@" 1>&2
}

filename=amazon_logo_test.jpg
stack=cloud2
bucket=cloud2.jamesoff.net

# get stack outputs
outputs=$( aws cloudformation describe-stacks --stack-name "$stack" --query 'Stacks[0].Outputs' )

AWS_ACCESS_KEY_ID=$( echo "$outputs" | jq -r '.[] | select(.OutputKey == "UploadUserAccessKey").OutputValue' )
export AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$( echo "$outputs" | jq -r '.[] | select(.OutputKey == "UploadUserSecretKey").OutputValue' )
export AWS_SECRET_ACCESS_KEY

QUEUE=$( echo "$outputs" | jq -r '.[] | select(.OutputKey == "CloudQueue").OutputValue' )
unset outputs

set -x

aws s3 rm "s3://$bucket/assets/$filename" || true

sleep 5

aws s3 cp "cloudformation/$filename" "s3://$bucket/assets/$filename"

message_json=""
attempts=0
while [[ $attempts -lt 6 ]]; do
	attempts=$(( attempts + 1 ))
	message_json=$( aws sqs receive-message \
		--wait-time-seconds 10 \
		--queue-url "$QUEUE"
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

curl "https://$bucket/$cloud_path"

aws sqs delete-message \
	--queue-url "$QUEUE" \
	--receipt-handle "$handle" || true
