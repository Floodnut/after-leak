import json
import boto3
import gzip
from time import time
from datetime import datetime
from discord_webhook import DiscordEmbed, DiscordWebhook

TO_KST = 3600 * 9
WEBHOOK_BASE_URL: str = "https://discord.com/api/webhooks"
NOT_USED_EVENT = {"CreateLogStream", "DescribeEventAggregates", "Decrypt"}
ATTACH_EVENTS = ["Create", "Run", "Put", "Post"]
DETTACH_EVENTS = ["Remove", "Delete"]
PERMITTED_EVENT = {"DescribeRegions", "ListRoles", "GetSendQuota", "ListUsers"}

WEBHOOK_URL = WEBHOOK_BASE_URL + "__webhook_uri__"

webhook_for_leak = DiscordWebhook(url=WEBHOOK_URL) # leak
webhook_for_root = DiscordWebhook(url=WEBHOOK_URL) # root
webhook_for_org_root = DiscordWebhook(url=WEBHOOK_URL) # org root

webhooks: dict = {
    "__your_integer_format_account_id__": webhook_for_leak,
    # add more webhook
    
    "unregistered": webhook_for_leak,
    
    "casperlake-sandbox": webhook_for_root,
    "casperlake-sandbox1": webhook_for_root,
    "sandbox1_root": webhook_for_root,
    
    "__your_integer_format_root_account_id__": webhook_for_org_root,
    "default": webhook_for_org_root,
}

webhooks_color: dict = {
    "__your_integer_format_account_id__": "03b2f8",
    
    "sandbox1_root": "3557aa",
    "sandbox1_management": "3557aa",
    
    "default": "aa5733",
}

user_name_dict = {
    "__your_integer_format_account_id__": "sandbox1_root",
    # add more user name
}

user_name_killchain_dict = {
    "__your_integer_format_account_id__": "sandbox1",
    # add more user name
}

sandbox_user_name = {
    "casperlake-sandbox1", 
    # add more sandbox user name
    "management"
}

def check_is_root(event_identity: dict, event_user: str) -> tuple:
    if "userName" in event_identity and event_identity.get("userName") not in sandbox_user_name:
        if event_user == "sandbox1_root":
            return (False, "__your_integer_format_account_id__")
            
    return (True, event_user) # (is_root, user_name)
    
def is_ignore(event_source, event_name, event_source_ip):
    result = {
        "ignore": False,
        "is_sts": False,
        "event" : None
    }
    
    if event_source == "sts":
        result["ignore"] = True
        result["is_sts"] = True
    
    if event_name in NOT_USED_EVENT:
        result["ignore"] = True
    
    if event_name.startswith("Get"):
        result["ignore"] = True
    
    if event_name in PERMITTED_EVENT:
        result["ignore"] = True
        result["event"] = f"{event_source} - {event_name}"
    
    if event_source_ip in ["AWS Internal"]:
        result["ignore"] = True
        
    return result


def send_webhook(bucket: str, key: str, events: list):
    """
    "eventTime": "2023-07-31T23:59:29Z",
    "eventSource": "s3.amazonaws.com",
    "eventName": "GetBucketAcl",
    "awsRegion": "ap-northeast-2",
    """
    is_sts: bool = False
    suspect_leaked: bool = False
    src: set = set()
    result: str = f"버킷 : {bucket}\n로그 : {key}"
    try:
        result += "\n로그 발생 시간(KST) :  " + str(datetime.fromtimestamp((time() + TO_KST)))
        result += f"\n\n총 이벤트 수 : {len(events)}"

        event_user: str = "default"
        event_region: str = "global"

        if "__your_integer_format_account_id__" in key:
            event_user = "sandbox1_root"

        can_call_killchain = False
        result_event_user = None
        for event in events:
            event_region = event.get("awsRegion")
            event_source = event.get("eventSource").split(".")[0]
            event_name = event.get("eventName")
            event_source_ip = event.get("sourceIPAddress")

            _ignore = is_ignore(event_source, event_name, event_source_ip)
            is_sts = _ignore["is_sts"]
            if _ignore["event"]:
                src.add(_ignore["event"])
                
            if _ignore["ignore"]:
                continue
            
            is_management, event_user = check_is_root(event.get("userIdentity"), event_user)

            suspect_leaked = not is_management

            if suspect_leaked:
                src.add(f"{event_source} - {event_name}  <- Leaked from {event_source_ip}")
                can_call_killchain = True
                result_event_user = event_user
                
                try:
                    res: dict = {"target": user_name_killchain_dict.get(result_event_user), "action": "attach", "event_source": event_source}
                    
                    lambda_client = boto3.client(
                        "lambda",
                        region_name="ap-northeast-2",
                    )
                    
                    lambda_res = lambda_client.invoke(
                        FunctionName="killchain",
                        InvocationType="Event",
                        Payload=json.dumps(res)
                    )
                    print(f"Killchain call.")
                except Exception as e:
                    print("Error occur during killchain.", e)
            else:
                src.add(f"{event_source} - {event_name} - {event_source_ip}")

        for e in list(src):
            result += f"\n{e}"

        try:
            webhook_title = f"[{event_region}] - User: {event_user}."
            if event_user not in webhooks:
                event_user = "unregistered"
                webhook_title += " > unregistered"
                
            embed = DiscordEmbed(
                title= webhook_title,
                description=result,
                color=webhooks_color[event_user],
            )
    
            webhooks.get(event_user).add_embed(embed)
            webhooks.get(event_user).execute()
        except Exception as e:
            print("Error occur during send webhook.", e)
        
    except json.JSONDecodeError:
        print("Error decoding JSON data")


def call_webhook_with_s3_object(bucket: str, key: str):
    print("[GET S3 Event] with :", key)
    s3 = boto3.client("s3")
    response = s3.get_object(Bucket=bucket, Key=key)
    with gzip.GzipFile(fileobj=response["Body"]) as gzip_file:
        obj = json.loads(gzip_file.read())

        try:
            if "logFiles" not in obj:  # CloudTrail-Digest 를 제외
                send_webhook(bucket, key, obj["Records"])
        except Exception as e:
            print(
                "Error getting object {} from bucket {}. Make sure they exist and your bucket is in the same region as this function.".format(
                    key, bucket
                )
            )
            raise e


def lambda_handler(event, context):
    # Get the object from the event and show its content type
    if (
        "messageId" in event["Records"][0]
        and event["Records"][0]["eventSource"] == "aws:sqs"
    ):  # SQS
        for record in event["Records"]:
            sqs_event = json.loads(record["body"])
            bucket = sqs_event["Records"][0]["s3"]["bucket"]["name"]
            key = sqs_event["Records"][0]["s3"]["object"]["key"]
            call_webhook_with_s3_object(bucket, key)
    else:  # S3 PUT
        bucket = event["Records"][0]["s3"]["bucket"]["name"]
        key = event["Records"][0]["s3"]["object"]["key"]
        call_webhook_with_s3_object(bucket, key)

    return None
