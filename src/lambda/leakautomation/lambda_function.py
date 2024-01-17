import json
import os
import boto3
import time
import uuid

from leak.githubleak import Githubleak
from dotenv import load_dotenv

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    load_dotenv()
    
    if event['target'] == "github":
        if event["action"] == "leak":
            githubleak = Githubleak(event["repo_name"], event["template"], event["keyvalues"])
            githubleak.leak()
            
            _log_state(event['target_account'], "working")
        elif event["action"] == "clean":
            githubleak = Githubleak(event["repo_name"], "", "")
            githubleak.clean()

    return {
        'statusCode': 200,
        'body': json.dumps('leak complate')
    }

def _log_state(account, state):
    state_table = dynamodb.Table('automation-state')
    log_table = dynamodb.Table('automation-log')

    log_table.put_item(
        Item={
            'ID': str(uuid.uuid4()),
            'account': account,
            'state': state,
            'timestamp': int(time.time())
        }
    )
    
    response = state_table.get_item(Key={'ID': account})
    
    item = response['Item']
    
    item['state'] = state
    item['timestamp'] = int(time.time())
    
    state_table.put_item(Item=item)
