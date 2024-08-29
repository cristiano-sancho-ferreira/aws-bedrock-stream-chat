import json
import boto3
import os

def lambda_handler(event, context):
    bedrock_model_id = os.environ['BEDROCK_MODEL_ID']
    
    bedrock_client = boto3.client('bedrock')
    
    response = bedrock_client.invoke_model(
        model_id=bedrock_model_id,
        content_type='application/json',
        payload=json.dumps({
            'text': event['text']
        })
    )
    
    result = json.loads(response['payload'].read())
    return {
        'statusCode': 200,
        'body': json.dumps(result)
    }
