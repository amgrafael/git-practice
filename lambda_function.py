import boto3 
 
ec2 = boto3.client("ec2") 
 
 
def lambda_handler(event, context): 
    instance_id = "i-01d075685bf245537"  
    response = ec2.stop_instances(InstanceIds=[instance_id]) 
 
    print(response) 
 
    return { 
        "statusCode": 200, 
        "body": "EC2 instance stopped successfully!", 
    }