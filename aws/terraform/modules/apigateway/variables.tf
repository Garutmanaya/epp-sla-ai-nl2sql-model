##############################################
# API Gateway Module Variables
##############################################

# Project name prefix
variable "project_name" {
  description = "Project name used for API Gateway naming"
  type        = string
}

# Lambda invoke ARN (used for integration URI)
variable "lambda_arn" {
  description = "Lambda invoke ARN for API Gateway integration"
  type        = string
}

# Lambda function name (used for permission resource)
variable "lambda_name" {
  description = "Lambda function name"
  type        = string
}

# AWS region (used to construct console/API URLs)
variable "region" {
  description = "AWS region"
  type        = string
}


