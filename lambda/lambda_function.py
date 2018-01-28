import boto3
import pystache
import urllib


def lambda_handler(event, context):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = urllib.unquote(record['s3']['object']['key'])
        print('Downloading template')
        template_body_response = s3.get_object(
            Bucket=bucket,
            Key='template/template.html'
        )
        template_body = template_body_response['Body'].read()
        target_object = 'v/{}'.format(record['s3']['object']['eTag'][0:8])
        rendered_template = bytes(pystache.render(template_body, {
            'url': key,
            'title': urllib.unquote_plus(key.split('/')[1])
        }))
        print('Writing rendered template to {}'.format(target_object))
        s3.put_object(
            Bucket=bucket,
            Key=target_object,
            Body=rendered_template,
            ContentType='text/html'
        )
        print('Done')


s3 = boto3.client('s3')

if __name__ == '__main__':
    lambda_handler({'Records': [
        {'s3': {
            'bucket': {'name': 'cloud.jamesoff.net'},
            'object': {'key': 'assets/test1.jpg', 'eTag': '123abc'}
        }}
    ]}, None)
