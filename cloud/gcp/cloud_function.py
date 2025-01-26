import json
import os
from google.cloud import monitoring_v3
from google.auth import compute_engine
from google.cloud import compute_v1
from datetime import datetime, timedelta

def get_gcp_metrics(project_id, instance_name, zone, metric_name='network/received_bytes_count'):
    """Fetch GCP metrics from Cloud Monitoring (Stackdriver)."""
    
    client = monitoring_v3.MetricServiceClient(credentials=compute_engine.Credentials())
    project_name = f"projects/{project_id}"
    
    now = datetime.utcnow()
    start_time = now - timedelta(hours=1)
    interval = monitoring_v3.types.TimeInterval(
        start=start_time,
        end=now
    )
    
    results = client.list_time_series(
        name=project_name,
        interval=interval,
        filter=f'metric.type="compute.googleapis.com/{metric_name}" AND resource.label.instance_id="{instance_name}"'
    )

    network_in = 0
    for result in results:
        for point in result.points:
            network_in += point.value.int64_value

    return network_in

def scale_instance(project_id, zone, instance_name, scale_up=True):
    """Scale GCP instance."""
    instance_client = compute_v1.InstancesClient(credentials=compute_engine.Credentials())
    operation = None

    if scale_up:
        operation = instance_client.start(project=project_id, zone=zone, instance=instance_name)
    else:
        operation = instance_client.stop(project=project_id, zone=zone, instance=instance_name)

    return f"Scaling {'Up' if scale_up else 'Down'}: {operation}"

def cloud_function(request):
    """Cloud Function to scale based on GCP metrics."""
    
    # Fetch environment variables
    project_id = os.getenv('GCP_PROJECT_ID')
    zone = os.getenv('GCP_ZONE')
    instance_name = os.getenv('GCP_INSTANCE_NAME')

    if not project_id or not zone or not instance_name:
        return json.dumps({'status': 'error', 'message': 'Missing environment variables.'})

    # Get metrics from GCP Monitoring
    metric_value = get_gcp_metrics(project_id, instance_name, zone)

    # Define scale thresholds
    scale_up_threshold = 50
    scale_down_threshold = 10

    # Scaling decision based on the metric
    if metric_value > scale_up_threshold:
        scale_message = scale_instance(project_id, zone, instance_name, scale_up=True)
    elif metric_value < scale_down_threshold:
        scale_message = scale_instance(project_id, zone, instance_name, scale_up=False)
    else:
        scale_message = f"No scaling required. Current metric value: {metric_value}"

    return json.dumps({'metric_value': metric_value, 'message': scale_message})