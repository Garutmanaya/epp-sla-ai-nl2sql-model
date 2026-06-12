##############################################
# Lambda Module
##############################################

##############################################
# Package Lambda Code
##############################################
# Converts Python file into deployable ZIP
##############################################

data "archive_file" "zip" {
  type        = "zip"
  source_file = "${path.root}/lambda_src/lambda_handler.py"
  output_path = "${path.root}/lambda.zip"
}

##############################################
# Lambda Function
##############################################

resource "aws_lambda_function" "lambda" {
  function_name = "${var.project_name}-relay"

  role    = var.lambda_role_arn
  handler = "lambda_handler.lambda_handler"
  runtime = "python3.11"

  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256

  timeout     = 30
  memory_size = 512

  environment {
    variables = {
      # Pass endpoint name to Lambda
      ENDPOINT_NAME = var.endpoint_name
    }
  }
}

##############################################
# Output
##############################################


# Correct Lambda ARN
output "lambda_arn" {
  value = aws_lambda_function.lambda.arn
}

# Function name
output "lambda_function_name" {
  value = aws_lambda_function.lambda.function_name
}

# API Gateway integration ARN (separate!)
output "lambda_invoke_arn" {
  value = aws_lambda_function.lambda.invoke_arn
}
