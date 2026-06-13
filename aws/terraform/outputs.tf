##############################################
# Structured Deployment Summary
##############################################

output "current_image" {
  description = "Currently deployed image"
  value       = var.ecr_image
}

output "api_key" {
  description = "API Gateway API Key"
  value       = module.apigateway.api_key
  sensitive   = true
}

output "deployment_summary" {
  description = "Complete deployment metadata"

  value = {
    project = "epp-sla-reporter-text2sql-model"

    ##########################################
    # AWS Environment
    ##########################################
    aws = {
      account_id   = data.aws_caller_identity.current.account_id
      caller_arn   = data.aws_caller_identity.current.arn
      principal    = element(split("/", data.aws_caller_identity.current.arn), 1)
      region       = data.aws_region.current.region
      partition    = data.aws_partition.current.partition
    }

    ##########################################
    # SageMaker
    ##########################################
    sagemaker = {
      endpoint_name = module.sagemaker.endpoint_name

      console_url = "https://${data.aws_region.current.region}.console.aws.amazon.com/sagemaker/home?region=${data.aws_region.current.region}#/endpoints/${module.sagemaker.endpoint_name}"
    }

    ##########################################
    # Lambda
    ##########################################
    lambda = {
      function_name = module.lambda.lambda_function_name

      console_url = "https://${data.aws_region.current.region}.console.aws.amazon.com/lambda/home?region=${data.aws_region.current.region}#/functions/${module.lambda.lambda_function_name}"
    }

    ##########################################
    # API Gateway
    ##########################################
    api_gateway = {
      api_id   = module.apigateway.api_id
      api_url  = module.apigateway.api_url

      console_url = "https://${data.aws_region.current.region}.console.aws.amazon.com/apigateway/home?region=${data.aws_region.current.region}#/apis/${module.apigateway.api_id}"
    }

    ##########################################
    # Derived / Operational Info
    ##########################################
    operational = {
      inference_endpoint = module.apigateway.api_url
      health_check       = "${module.apigateway.api_url}"

      curl_example = "curl -X POST ${module.apigateway.api_url} -H 'Content-Type: application/json' -d '{\"model_name\":\"test\",\"data\":{}}'"
    }
  }
}
