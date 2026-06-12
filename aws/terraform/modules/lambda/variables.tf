##############################################
# Lambda Module Variables
##############################################

# Project name prefix
variable "project_name" {
  description = "Project name for Lambda function naming"
  type        = string
}

# IAM role ARN for Lambda execution
variable "lambda_role_arn" {
  description = "IAM role ARN for Lambda execution"
  type        = string
}

# SageMaker endpoint name (passed to Lambda as env var)
variable "endpoint_name" {
  description = "SageMaker endpoint name"
  type        = string
}
