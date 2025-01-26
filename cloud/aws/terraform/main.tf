provider "aws" {
  region = var.aws_region
}

resource "aws_lambda_function" "elasticstack_lambda" {
  function_name = "elasticstack-lambda"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  filename      = "lambda_function.zip"  # Make sure to zip your function code

  environment {
    variables = {
      AWS_INSTANCE_ID     = var.aws_instance_id  # EC2 Instance ID to be scaled
      AWS_METRIC_NAME     = var.aws_metric_name  # Metric to scale by
      AWS_SCALE_UP_THRESHOLD   = var.aws_scale_up_threshold
      AWS_SCALE_DOWN_THRESHOLD = var.aws_scale_down_threshold
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "elasticstack_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "elasticstack_lambda_policy"
  description = "Policy to allow Lambda to interact with EC2 and CloudWatch"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ec2:StartInstances", "ec2:StopInstances"]
        Resource = var.aws_instance_id  # Restrict the policy to the specific instance
        Effect   = "Allow"
      },
      {
        Action   = ["cloudwatch:GetMetricStatistics"]
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_exec_role.name
}

# Output the Lambda function ARN for user convenience
output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.elasticstack_lambda.arn
}

# Define variables
variable "aws_region" {
  description = "AWS region for Lambda function"
  default     = "us-east-1"
}

variable "aws_instance_id" {
  description = "EC2 Instance ID to scale"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime version"
  default     = "python3.8"
}

variable "aws_metric_name" {
  description = "CloudWatch metric name to use for scaling"
  default     = "NetworkIn"
}

variable "aws_scale_up_threshold" {
  description = "Threshold to scale up"
  default     = 50
}

variable "aws_scale_down_threshold" {
  description = "Threshold to scale down"
  default     = 10
}