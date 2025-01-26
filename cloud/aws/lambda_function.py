import json
import boto3
import os
from datetime import datetime, timedelta

# Initialize AWS clients
cloudwatch = boto3.client('cloudwatch')
ec2 = boto3.client('ec2')

def get_aws_metrics(instance_id, metric_name, namespace='AWS/EC2', period=300):
    """Fetch CloudWatch metrics for the specified EC2 instance."""
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(hours=1)
    
    response = cloudwatch.get_metric_statistics(
        Period=period,
        StartTime=start_time,
        EndTime=end_time,
        MetricName=metric_name,
        Namespace=namespace,
        Dimensions=[{
            'Name': 'InstanceId',
            'Value': instance_id
        }]
    )
    
    if response['Datapoints']:
        return response['Datapoints'][-1]['Average']
    return 0

def scale_instance(instance_id, scale_up=True):
    """Scale EC2 instance by starting or stopping."""
    if scale_up:
        ec2.start_instances(InstanceIds=[instance_id])
        return f"Scaling Up: Starting instance {instance_id}"
    else:
        ec2.stop_instances(InstanceIds=[instance_id])
        return f"Scaling Down: Stopping instance {instance_id}"

def lambda_handler(event, context):
    """Lambda function to scale EC2 instance based on CloudWatch metrics."""
    # Fetch the environment variables
    instance_id = os.getenv('AWS_INSTANCE_ID')
    metric_name = os.getenv('AWS_METRIC_NAME', 'NetworkIn')
    scale_up_threshold = int(os.getenv('AWS_SCALE_UP_THRESHOLD', 50))
    scale_down_threshold = int(os.getenv('AWS_SCALE_DOWN_THRESHOLD', 10))

    if not instance_id:
        return {"statusCode": 400, "body": json.dumps("AWS_INSTANCE_ID not set in environment variables.")}

    # Get CloudWatch metrics
    metric_value = get_aws_metrics(instance_id, metric_name)

    # Scaling decision based on thresholds
    if metric_value > scale_up_threshold:
        scale_message = scale_instance(instance_id, scale_up=True)
    elif metric_value < scale_down_threshold:
        scale_message = scale_instance(instance_id, scale_up=False)
    else:
        scale_message = f"No scaling required. Current metric value: {metric_value}"

    print(f"Metric value: {metric_value}, Scaling action: {scale_message}")
    return {
        'statusCode': 200,
        'body': json.dumps({
            'metric_value': metric_value,
            'message': scale_message
        })
    }   