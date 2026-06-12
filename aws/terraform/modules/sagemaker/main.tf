##############################################
# SageMaker Module
##############################################
# Extract tag to for configuration resources tag
# Replace dot with -
locals {
  image_tag_raw = element(split(":", var.ecr_image), 1)

  # Replace invalid characters
  image_tag = replace(local.image_tag_raw, ".", "-")
}
##############################################
# Model Definition
##############################################
# Links your ECR image to SageMaker
# No S3 model artifact required
##############################################

resource "aws_sagemaker_model" "model" {
  #name               = "${var.project_name}-model"
  name = "${var.project_name}-model-${local.image_tag}"
  execution_role_arn = var.sagemaker_role_arn

  primary_container {
    image = var.ecr_image
  }
}

##############################################
# Endpoint Configuration (Serverless)
##############################################
# Defines memory and concurrency limits
##############################################

resource "aws_sagemaker_endpoint_configuration" "config" {
  #name = "${var.project_name}-config"
  name = "${var.project_name}-config-${local.image_tag}"

  production_variants {
    variant_name = "AllTraffic"
    model_name   = aws_sagemaker_model.model.name

    serverless_config {
      memory_size_in_mb = var.memory_size
      max_concurrency   = var.max_concurrency
    }
  }
}

##############################################
# Endpoint
##############################################
# This is the actual inference endpoint
##############################################

resource "aws_sagemaker_endpoint" "endpoint" {
  name                 = "${var.project_name}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.config.name
}


##############################################
# Output
##############################################

output "endpoint_name" {
  value = aws_sagemaker_endpoint.endpoint.name
}
