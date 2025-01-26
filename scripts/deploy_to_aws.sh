#!/bin/bash

# Ensure AWS CLI is configured and logged in

# Variables
INSTANCE_ID=$1
AWS_REGION=$2

# Validate the provided EC2 instance ID and region
if [ -z "$INSTANCE_ID" ]; then
  echo "Please provide an EC2 instance ID."
  exit 1
fi
if [ -z "$AWS_REGION" ]; then
  echo "Please provide the AWS region."
  exit 1
fi

# Package the Lambda function code into a zip file
zip lambda_function.zip cloud/aws/lambda_function.py

# Change to the Terraform directory
cd cloud/aws/terraform

# Initialize Terraform
terraform init

# Apply Terraform configuration with the provided instance ID and region
terraform apply -var "aws_instance_id=${INSTANCE_ID}" -var "aws_region=${AWS_REGION}" -auto-approve