import boto3
import pystache
import urllib
import os


def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = urllib.unquote(record['s3']['object']['key'])
        key_filename = key.split('/')[1]
        print('Downloading template')
        template_body_response = s3.get_object(
            Bucket=bucket,
            Key='template/template.html'
        )
        template_body = template_body_response['Body'].read()
        target_filename = record['s3']['object']['eTag'][0:8]
        target_object = 'v/{}'.format(target_filename)
        rendered_template = bytes(pystache.render(template_body, {
            'url': key,
            'title': urllib.unquote_plus(key_filename)
        }))
        print('Writing rendered template to {}'.format(target_object))
        s3.put_object(
            Bucket=bucket,
            Key=target_object,
            Body=rendered_template,
            ContentType='text/html',
            StorageClass='STANDARD_IA'
        )
        sqs.send_message(
            QueueUrl=CLOUD_QUEUE,
            MessageBody='{}={}'.format(key_filename, target_object)
        )
        print('Done')


s3 = boto3.client('s3')
sqs = boto3.client('sqs')

CLOUD_QUEUE = os.environ['CLOUD_QUEUE']

if __name__ == '__main__':
    lambda_handler({'Records': [
        {'s3': {
            'bucket': {'name': 'cloud.jamesoff.net'},
            'object': {'key': 'assets/test1.jpg', 'eTag': '123abc'}
        }}
    ]}, None)
