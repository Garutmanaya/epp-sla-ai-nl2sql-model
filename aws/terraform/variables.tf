##############################################
# Input Variables
##############################################

# AWS region where all resources will be deployed
variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

# ECR image that contains your FastAPI + models
variable "ecr_image" {
  description = "Full ECR image URI"
  type = string
}

# Serverless memory configuration for SageMaker
# This directly impacts CPU allocation and cost
variable "memory_size" {
  description = "Memory for SageMaker Serverless (MB)"
  default     = 2048
}

# Maximum concurrent requests SageMaker can handle
variable "max_concurrency" {
  description = "Max concurrent invocations"
  default     = 5
}
