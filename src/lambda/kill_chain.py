import json
import boto3
import uuid
import time

idset = {
    "sandbox1": "__account_id__", # this is int-format string
    ## add aditional accounts here
}

target = {
    "sandbox1" : "github",
    ## add aditional accounts here
}

def lambda_handler(event, context):
    
    print(event)

    session = boto3.Session()
    
    org = session.client('organizations')

    target_account_id = idset.get(event['target'])
    target_policy_id = "__your_kill_chain_scp_id__" # kill chain scp id
        
    if event['action'] == "attach": 
        org.attach_policy(
            PolicyId = target_policy_id,
            TargetId = target_account_id
        )
        
        _log_state(event['target'], "compromised")
        
        _repo_clean(event['target'])
        _nuke(event['target'])
        
        
    elif event['action'] == "detach":
        org.detach_policy(
            PolicyId = target_policy_id,
            TargetId = target_account_id
        )

        _log_state(event['target'], "idle")


    return {
        'statusCode': 200,
        'body': json.dumps('Done!')
    }

def _log_state(account, state):
    dynamodb = boto3.resource('dynamodb')
    
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


def _nuke(account):
    lambda_client = boto3.client('lambda')
    
    eventjson: dict = {
        "target_account": account
    }
    
    lambda_client.invoke(
            FunctionName='nuke-booster',
            InvocationType='Event',
            Payload=json.dumps(eventjson)
    ) 

def _repo_clean(account):
    lambda_client = boto3.client('lambda')

    eventjson: dict = {
      "target": target[account],
      "action": "clean",
      "repo_name": "settings",
      "target_account": account,
      "template": "env"
    }
    
    lambda_client.invoke(
            FunctionName='Leak_Automation',
            InvocationType='Event',
            Payload=json.dumps(eventjson)
    ) 
""" 
event1 = {
  "target": "sandbox1",
  "action": "attach"
}

lambda_handler(event1, "") """