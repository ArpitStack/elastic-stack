#!/bin/bash

# Ensure you're logged in to Azure CLI
# az login

# Variables
VM_NAME=$1
AZURE_LOCATION=$2
AZURE_SUBSCRIPTION_ID=$3
AZURE_RESOURCE_GROUP=$4

# Validate that the required variables are provided
if [ -z "$VM_NAME" ]; then
  echo "Please provide the Azure VM name."
  exit 1
fi
if [ -z "$AZURE_LOCATION" ]; then
  echo "Please provide the Azure location."
  exit 1
fi
if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
  echo "Please provide the Azure subscription ID."
  exit 1
fi
if [ -z "$AZURE_RESOURCE_GROUP" ]; then
  echo "Please provide the Azure resource group."
  exit 1
fi

# Package the Azure Function code
zip function-code.zip cloud/azure/azure_function.py

# Change to the Terraform directory
cd cloud/azure/terraform

# Initialize Terraform
terraform init

# Apply Terraform configuration with the provided Azure parameters
terraform apply -var "azure_location=${AZURE_LOCATION}" -var "azure_subscription_id=${AZURE_SUBSCRIPTION_ID}" -var "azure_resource_group=${AZURE_RESOURCE_GROUP}" -var "azure_vm_name=${VM_NAME}" -auto-approve