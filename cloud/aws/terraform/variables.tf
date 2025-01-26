variable "aws_region" {
  description = "AWS region for Lambda function"
  default     = "us-east-1"
}

variable "aws_instance_id" {
  description = "EC2 Instance ID to scale"
  type        = string
}