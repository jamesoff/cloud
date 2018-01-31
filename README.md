# Cloud image hosting

Early days; some assembly required.

This is my home-cooked version of cloud-based image hosting a la CloudApp. The flow is:

* image is uploaded to an S3 bucket by the upload script
* S3 triggers a Lambda function which writes an HTML wrapper for that image and writes that back to the bucket at a new prefix
* the Lambda function posts to an SQS queue with the path that the HTML file is available at
* the upload script retrieves the message from the queue and prints the URL to the file
* CloudFront sits in front of S3 to do HTTPS and caching

## Approximate deployment instructions

uh, pretty sure you can figure it out from the code and the above. If not, this probably isn't for you anyway ;)

Better instructions to follow.

## Approximate usage instructions

```
% ./post-image.sh Ksov89X.png
https://cloud.jamesoff.net/v/dbaa1926
```

## Architecture

![Image of architecture](https://raw.githubusercontent.com/jamesoff/cloud/master/gh-assets/aws.png)
