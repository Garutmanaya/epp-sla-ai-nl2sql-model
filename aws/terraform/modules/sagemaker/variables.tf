##############################################
# SageMaker Module Variables
##############################################

# Project name for resource naming
variable "project_name" {
  description = "Project name prefix"
  type        = string
}

# ECR image URI (required)
variable "ecr_image" {
  description = "Full ECR image URI containing model + inference code"
  type        = string
}

# IAM role ARN for SageMaker execution
variable "sagemaker_role_arn" {
  description = "IAM role ARN for SageMaker execution"
  type        = string
}

# Serverless memory configuration
variable "memory_size" {
  description = "Memory size for SageMaker serverless endpoint (MB)"
  type        = number
}

# Serverless concurrency configuration
variable "max_concurrency" {
  description = "Maximum concurrent invocations"
  type        = number
}
