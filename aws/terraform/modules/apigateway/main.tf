##############################################
# API Gateway Module
##############################################

##############################################
# Create REST API
##############################################

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.project_name}-api"
}

##############################################
# Create /ping resource
##############################################

resource "aws_api_gateway_resource" "ping" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "ping"
}

##############################################
# Create /predict resource
##############################################

resource "aws_api_gateway_resource" "predict" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "predict"
}

##############################################
# Define GET method for /ping
##############################################

resource "aws_api_gateway_method" "ping_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.ping.id
  http_method   = "GET"

  authorization = "NONE"
  api_key_required = true   # keep same security model
}

##############################################
# Define POST method /predict
##############################################

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.predict.id
  http_method   = "POST"
  authorization = "NONE"

  # ✅ Require API key
  api_key_required = true
}

##############################################
# Integrate /ping with Lambda
##############################################

resource "aws_api_gateway_integration" "ping_lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.ping.id
  http_method = aws_api_gateway_method.ping_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  uri = var.lambda_arn
}

##############################################
# Integrate with Lambda
##############################################

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.predict.id
  http_method = aws_api_gateway_method.post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  # Connect API Gateway → Lambda
  uri = var.lambda_arn
}

##############################################
# Permission: API Gateway → Lambda
##############################################

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"

  # ✅ Correct: function name (or plain lambda ARN)
  function_name = var.lambda_name

  principal     = "apigateway.amazonaws.com"
}

##############################################
# Deploy API
##############################################

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.lambda]

  rest_api_id = aws_api_gateway_rest_api.api.id

  # Important: force redeploy when config changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.predict.id,
      aws_api_gateway_method.post.id,
      aws_api_gateway_method.post.api_key_required,   # ✅ API KEY REQUIRED
      aws_api_gateway_integration.lambda.id, 

      # Ping Triggers
      aws_api_gateway_resource.ping.id,
      aws_api_gateway_method.ping_get.id,
      aws_api_gateway_method.ping_get.api_key_required, 
      aws_api_gateway_integration.ping_lambda.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

##############################################
# Stage
##############################################

resource "aws_api_gateway_stage" "stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}

##############################################
# API KEY (NEW)
##############################################

resource "aws_api_gateway_api_key" "key" {
  name = "${var.project_name}-api-key"
}

##############################################
# Usage Plan (UPDATED: add throttling + quota)
##############################################

resource "aws_api_gateway_usage_plan" "plan" {
  name = "${var.project_name}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }

  # Throttle settings (per second)
  throttle_settings {
    rate_limit  = 5    # steady RPS allowed
    burst_limit = 10   # short burst capacity
  }

  # Monthly quota (optional)
  quota_settings {
    limit  = 10000     # requests/month
    period = "MONTH"
  }
}

##############################################
# Attach API Key to Usage Plan (NEW)
##############################################

resource "aws_api_gateway_usage_plan_key" "attach" {
  key_id        = aws_api_gateway_api_key.key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.plan.id
}

##############################################
# Output
##############################################

output "api_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/prod/predict"
}

output "ping_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/prod/ping"
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.api.id
}

##############################################
# API Key Output (NEW)
##############################################

output "api_key" {
  description = "API Gateway API Key"
  value       = aws_api_gateway_api_key.key.value
  sensitive   = true
}
