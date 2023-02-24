import boto3
import logging
import json
from botocore.config import Config
import os
import datetime


# Region
region="us-east-1"


# Boto core maximum retries
config = Config(
    retries = {
      'max_attempts': 10,
      'mode': 'standard'
   }
)


# Initialize boto3 clients
ssm_client = boto3.client('ssm', region_name=region, config=config)
s3_client = boto3.client("s3", region_name=region)
s3_resource = boto3.resource("s3", region_name=region)
cloudwatch_client = boto3.client("cloudwatch", region_name=region)
ec2_client = boto3.client("ec2", region_name=region, config=config)


# Sets logging
logger = logging.getLogger("custom_logger")
logger.setLevel(logging.INFO)

# The bucket contains auto remediation configs
bucket_name = os.environ["CONFIG_BUCKET"]
# The path in the bucket where configs are available
config_filepath = os.environ["CONFIG_PATH"]

# Remediation config is downloaded by lambda locally in the
# following path
download_path = "/tmp"


# Execute the run command by ssm and return the CommandId
def perform_remediation_ssm_run_command(instance_id, 
        commands, alarm_name, platform):
    
    try:
        run_type = ""
        # The operating system
        if platform == "linux":
            run_type = "AWS-RunShellScript"
        else:
            run_type = "AWS-RunPowerShellScript"

        # Send command to the SSM to execute
        response = ssm_client.send_command(
                InstanceIds=[instance_id],
                DocumentName=run_type,
                Parameters={'commands': commands})
        
        return response['Command']['CommandId']
    except Exception as e:
        logger.error("SSM command failed for the alarm "+alarm_name)
        raise e


# Construct the message to be send to SQS
def construct_message(commands, alarm_configdata):
    message = {}
    message["retry_attempt"] = 0
    message["execute_commands"] = commands
    message["metric_name"] = alarm_configdata["metric_name"]
    message["alarm_name"] = alarm_configdata["alarm_name"]
    message["alarm_triger_time"] = datetime.datetime.today().strftime('%Y-%m-%d-%H:%M:%S')
    message["instance_id"] = alarm_configdata["instance_id"]
    return message


# Parse the downloaded config file
def read_file(alarm_configdata):
    global download_path, file_name
    
    commands = []
    
    if os.path.exists(os.path.join(download_path,file_name)):
        file=open(os.path.join(download_path,file_name),"r")
        contents = file.read().splitlines()
  
        for current_line in contents:
            commands.append(current_line.strip())
    
    if len(commands) > 0:
        return construct_message( commands, alarm_configdata)


# Download the config file from s3 bucket
def download_config_from_s3_bucket(object_key):
    global download_path, file_name, bucket_name
    
    bucket = s3_resource.Bucket(bucket_name)
    
    try:
        file_name = object_key[object_key.index("/")+1:len(object_key)]
        file_object = bucket.Object(object_key) 
        # download the file in the current directory
        file_object.download_file(os.path.join(download_path,file_name))        
        return True 
    except Exception as e:
        logger.error(f"Error in downloading alarm config file for the product file {object_key} : {str(e)}")
        return False


# To find all ssm configuration files
def find_remediation_config(alarm_configdata):
    global bucket_name, config_filepath
    
    response = s3_client.list_objects_v2(
        Bucket=bucket_name, MaxKeys=1000,
        Prefix=config_filepath )["Contents"]
    
    is_config_available = False
    
    file_key=""
    
    for file_key in response:
        if file_key["Key"] != config_filepath:
            object_key=file_key["Key"][file_key["Key"].index("/")+1:len(file_key["Key"])]
            
            if "#" in object_key:
                metric_name=object_key[0:object_key.index("#")]
            else:
                continue
            
            if metric_name in alarm_configdata["metric_name"]:
                is_config_available = True
                file_key=file_key["Key"]
                break

    if is_config_available:
        return download_config_from_s3_bucket(file_key)
    else:
        logger.error(f"Auto-remediation config not available in s3 bucket for metric {alarm_configdata['alarm_name']}, so process fails." +
                     " Web service notification sns triggered.")
        return False

# Get the EC2 platform
def get_ec2_platform(instance_id):
    response_ec2 = ec2_client.describe_instances(InstanceIds=[instance_id])
    
    # As per boto3 documentation, if platform key is missing then Linux else Windows
    if "Platform" in response_ec2["Reservations"][0]["Instances"][0] and \
        response_ec2["Reservations"][0]["Instances"][0]["Platform"].lower() == "windows":
        return "windows"
    else:
        return "linux"


# Get the metric name from alarm name
def get_metric_name_instance_id(alarm_name):
    response = cloudwatch_client.describe_alarms(
        AlarmNames=[alarm_name] )["MetricAlarms"][0]
    
    metric_name = response["MetricName"]
    
    dimensions = response["Dimensions"]
    
    instance_id = ""
    
    for dimension in dimensions:
        if dimension['Name'].lower() == "instanceid":
            instance_id = dimension['Value']
    
    
    return { "metric_name" : metric_name, "instance_id": instance_id, 
                "alarm_name" : alarm_name, "platform" : get_ec2_platform(instance_id) }


# Main lambda function
def lambda_handler(event, context):

    # Capture the event    
    logger.info(event)

    # Parse the sns message to extract the data
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    
    if sns_message["NewStateValue"].lower() == "alarm":
        alarm_name=sns_message["AlarmName"]
        alarm_configdata=get_metric_name_instance_id(alarm_name)
        
        # To find the remediation config file
        if find_remediation_config(alarm_configdata):
            # Parse the file, construct the actions and send to SQS
            message = read_file(alarm_configdata)
            # Perform the remediation
            perform_remediation_ssm_run_command(message["instance_id"],
                message["execute_commands"],
                message["alarm_name"],
                alarm_configdata["platform"])

            logger.info("autoremediation performed")
            return {
                "statusCode": 200,
                "message": "autoremediation performed"
            }
        else:
            logger.info("no autoremediation solution found")

            return {
                "statusCode": 204,
                "message": "no autoremediation solution found"
            }
