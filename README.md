# Cloud image hosting

This is my home-cooked version of cloud-based image hosting a la CloudApp. The flow is:

* image is uploaded to an S3 bucket by the upload script
* S3 triggers a Lambda function which asks Rekognition to supply some tags for the image, then writes an HTML wrapper for that it and writes that back to the bucket at a new prefix
* the Lambda function posts to an SQS queue with the path that the HTML file is available at
* the upload script retrieves the message from the queue and prints the URL to the file
* CloudFront sits in front of S3 to do HTTPS and caching

## Approximate deployment instructions

### Dependencies

* an AWS account
* the awscli installed

### Do this

* In us-east-1, create an ACM certification for the name you want to use for hosting (or upload one)
* Once the certificate is ready, launch a CloudFormation stack using the supplied template (in whichever region, although probably one with Rekognition is a good idea)
	* The `DomainName` parameter is the full domain name you want to use (same as your ACM cert)
	* `AcmCertificate` is the ARN for the cert you generated
	* `HostedZoneName` is the Route53 zone to create the alias to CloudFront in, which means if DomainName is `cloud.jamesoff.net` it's `jamesoff.net.` (with the trailing dot). If your domain isn't in Route53, you should leave this blank.
	* `TwitterHandle` is optional; if set it's used in the metadata of the HTML
	* `KeySerial` should start at `1`. If you want to rotate the access key pair for uploading, update the stack and increment it
* Wait about 45 minutes for the stack to be complete. CloudFront takes AGES to start/configure.
* `mkdir -p ~/.config/cloud`
* Edit `config` in the above directory thusly:

```
CLOUD_DOMAIN=[your DomainName value]
CLOUD_QUEUE=[get this from the Stack Outputs]
CLOUD_PROFILE=[a profile name for the awscli; I use cloud]
CLOUD_BUCKET=[your DomainName value too]
```

* Edit `~/.aws/credentials` and add a profile named as per above, with the access key/secret the stack Outputs gives you, and the right default region
* With a profile (`export AWS_PROFILE=...; export AWS_DEFAULT_REGION=...`) which has write access to the bucket (not the credentials you just put in the config, those can only upload images), `./deploy.sh` to upload the template and js/css to S3.
 
## Approximate usage instructions

```
% ./post-image.sh Ksov89X.png
https://cloud.jamesoff.net/v/dbaa1926
```

I have the following in my zsh config to allow me to run `post image.jpg` and `post-recent-screenshot`. The URL to the hosted image is placed in my clipboard.

```sh
if [[ -x ~/src/cloud/post-image.sh ]]; then
	function post() {
		post_url=$( ~/src/cloud/post-image.sh "$1" )
		if [[ -n $post_url ]]; then
			echo "--> $post_url"
			post_url=$( echo -n $post_url | tr -d '\n' )
			export POST_LAST_URL=$post_url
			echo -n $post_url | pbc
		else
			echo "Failed."
		fi
	}
else
	function post() {
		echo 'cloud post-image.sh is not available or not executable'
	}
fi
alias post-recent-screenshot='post ~/Desktop/Screen\ Shot\ *(om[1])'
```

## Architecture

![Image of architecture](https://raw.githubusercontent.com/jamesoff/cloud/master/gh-assets/aws.png)
