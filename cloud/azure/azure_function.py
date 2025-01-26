import json
import os
from azure.identity import DefaultAzureCredential
from azure.mgmt.monitor import MonitorManagementClient
from azure.mgmt.compute import ComputeManagementClient
from datetime import datetime, timedelta

def get_azure_metrics(subscription_id, resource_group, vm_name, metric_name='NetworkIn'):
    """Fetch Azure metrics using Azure Monitor."""
    credential = DefaultAzureCredential()
    monitor_client = MonitorManagementClient(credential, subscription_id)
    
    # Time range for metrics
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(hours=1)
    
    metrics = monitor_client.metrics.list(
        resource_uri=f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Compute/virtualMachines/{vm_name}",
        timespan=f"{start_time.isoformat()}/{end_time.isoformat()}",
        metricnames=metric_name
    )

    network_in = 0
    for metric in metrics.value:
        if metric.name.value == metric_name:
            for timeseries in metric.timeseries:
                for data in timeseries.data:
                    network_in += data.average or 0

    return network_in

def scale_vm(subscription_id, resource_group, vm_name, scale_up=True):
    """Scale Azure VM instance."""
    credential = DefaultAzureCredential()
    compute_client = ComputeManagementClient(credential, subscription_id)
    
    vm = compute_client.virtual_machines.get(resource_group, vm_name)
    
    # Scaling logic (In this case, we simulate by deallocating and starting the VM)
    if scale_up:
        compute_client.virtual_machines.start(resource_group, vm_name)
        return f"Scaling Up: Starting VM {vm_name}"
    else:
        compute_client.virtual_machines.deallocate(resource_group, vm_name)
        return f"Scaling Down: Stopping VM {vm_name}"

def azure_function(req):
    """Azure Function to scale based on Azure metrics."""
    
    # Fetch environment variables
    subscription_id = os.getenv('AZURE_SUBSCRIPTION_ID')
    resource_group = os.getenv('AZURE_RESOURCE_GROUP')
    vm_name = os.getenv('AZURE_VM_NAME')
    metric_name = os.getenv('AZURE_METRIC_NAME', 'NetworkIn')
    scale_up_threshold = int(os.getenv('AZURE_SCALE_UP_THRESHOLD', 50))
    scale_down_threshold = int(os.getenv('AZURE_SCALE_DOWN_THRESHOLD', 10))

    if not subscription_id or not resource_group or not vm_name:
        return json.dumps({'status': 'error', 'message': 'Missing environment variables.'})

    # Get metrics from Azure Monitor
    metric_value = get_azure_metrics(subscription_id, resource_group, vm_name, metric_name)

    # Scaling decision based on thresholds
    if metric_value > scale_up_threshold:
        scale_message = scale_vm(subscription_id, resource_group, vm_name, scale_up=True)
    elif metric_value < scale_down_threshold:
        scale_message = scale_vm(subscription_id, resource_group, vm_name, scale_up=False)
    else:
        scale_message = f"No scaling required. Current metric value: {metric_value}"

    print(f"Metric value: {metric_value}, Scaling action: {scale_message}")
    return json.dumps({'metric_value': metric_value, 'message': scale_message})