import boto3
import pystache
import urllib
import os

from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

patch_all()


def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = urllib.unquote_plus(record['s3']['object']['key'])
        key_filename = key.split('/')[1]
        print('Downloading template')
        template_body_response = s3.get_object(
            Bucket=bucket,
            Key='template/template.html'
        )
        template_body = template_body_response['Body'].read()
        target_filename = record['s3']['object']['eTag'][0:8]
        target_object = 'v/{}'.format(target_filename)
        labels = []
        if CLOUD_BUCKET_REGION is not None:
            try:
                response = rekognition.detect_labels(Image={'S3Object': {
                    'Bucket': bucket,
                    'Name': key
                }})
                labels = [x['Name'] for x in response['Labels'] if x['Confidence'] > 90]
            except Exception as e:
                print('Failed to rekognition: {}, {}'.format(key, e))
        if len(labels):
            label_list = ', '.join(labels)
            page_title = '{} ({})'.format(key_filename, label_list)
            description = 'An image, probably of {}'.format(label_list)
        else:
            description = 'An image shared with cloud'
            page_title = key_filename
            label_list = ''

        xray_recorder.begin_subsegment('render_template')
        rendered_template = bytes(pystache.render(template_body, {
            'url': key,
            'title': key_filename,
            'page_title': page_title,
            'domain_name': bucket,
            'target_object': target_object,
            'twitter': CLOUD_TWITTER,
            'has_twitter': CLOUD_TWITTER is not None,
            'description': description
        }))
        xray_recorder.end_subsegment()
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
CLOUD_TWITTER = os.environ.get('CLOUD_TWITTER', None)
CLOUD_BUCKET_REGION = os.environ.get('CLOUD_BUCKET_REGION', None)

if CLOUD_BUCKET_REGION is not None:
    rekognition = boto3.client('rekognition', CLOUD_BUCKET_REGION)

if __name__ == '__main__':
    lambda_handler({'Records': [
        {'s3': {
            'bucket': {'name': 'cloud.jamesoff.net'},
            'object': {'key': 'assets/test1.jpg', 'eTag': '123abc'}
        }}
    ]}, None)
