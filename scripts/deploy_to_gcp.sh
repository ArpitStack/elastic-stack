#!/bin/bash

# Ensure you're logged in to Google Cloud SDK
# gcloud auth login

# Variables
GCP_PROJECT_ID=$1
GCP_REGION=$2
GCP_ZONE=$3
GCP_INSTANCE_NAME=$4

# Validate that the required variables are provided
if [ -z "$GCP_PROJECT_ID" ]; then
  echo "Please provide the GCP project ID."
  exit 1
fi
if [ -z "$GCP_REGION" ]; then
  echo "Please provide the GCP region."
  exit 1
fi
if [ -z "$GCP_ZONE" ]; then
  echo "Please provide the GCP zone."
  exit 1
fi
if [ -z "$GCP_INSTANCE_NAME" ]; then
  echo "Please provide the GCP instance name."
  exit 1
fi

# Package the Cloud Function code
zip function-code.zip cloud/gcp/cloud_function.py

# Change to the Terraform directory
cd cloud/gcp/terraform

# Initialize Terraform
terraform init

# Apply Terraform configuration with the provided GCP parameters
terraform apply -var "gcp_project_id=${GCP_PROJECT_ID}" -var "gcp_zone=${GCP_ZONE}" -var "gcp_instance_name=${GCP_INSTANCE_NAME}" -auto-approve