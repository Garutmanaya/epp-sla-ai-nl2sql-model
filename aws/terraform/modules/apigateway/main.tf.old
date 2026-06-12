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
# Create /predict resource
##############################################

resource "aws_api_gateway_resource" "predict" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "predict"
}

##############################################
# Define POST method
##############################################

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.predict.id
  http_method   = "POST"
  authorization = "NONE"
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
      aws_api_gateway_integration.lambda.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}

##############################################
# Output
##############################################

output "api_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/prod/predict"
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.api.id
}
