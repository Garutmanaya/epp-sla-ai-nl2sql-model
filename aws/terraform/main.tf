##############################################
# Root Module - Orchestrates all submodules
##############################################

# Central naming convention to avoid duplication
locals {
  project_name = "epp-sla-reporter-text2sql"
}

##############################################
# IAM Module
##############################################
# Creates:
# - SageMaker execution role
# - Lambda execution role
##############################################

module "iam" {
  source       = "./modules/iam"
  project_name = local.project_name
}

##############################################
# SageMaker Module
##############################################
# Creates:
# - Model (linked to ECR image)
# - Serverless endpoint config
# - Endpoint
##############################################

module "sagemaker" {
  source              = "./modules/sagemaker"
  project_name        = local.project_name
  ecr_image           = var.ecr_image

  # Role created by IAM module
  sagemaker_role_arn  = module.iam.sagemaker_role_arn

  memory_size         = var.memory_size
  max_concurrency     = var.max_concurrency
}

##############################################
# Lambda Module
##############################################
# Creates:
# - Lambda relay function
# - Packages Python code into ZIP
##############################################

module "lambda" {
  source          = "./modules/lambda"
  project_name    = local.project_name

  # IAM role from module
  lambda_role_arn = module.iam.lambda_role_arn

  # Pass SageMaker endpoint name to Lambda
  endpoint_name   = module.sagemaker.endpoint_name
}

##############################################
# API Gateway Module
##############################################
# Creates:
# - REST API
# - /predict endpoint
# - Integration with Lambda
##############################################

module "apigateway" {
  source = "./modules/apigateway"

  project_name = local.project_name

  # Correct separation
  lambda_arn      = module.lambda.lambda_invoke_arn
  lambda_name     = module.lambda.lambda_function_name

  region = var.region
}
