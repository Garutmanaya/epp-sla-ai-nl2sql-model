##############################################
# IAM Module
##############################################

##############################################
# SageMaker Execution Role
##############################################
# This role allows SageMaker to:
# - Pull images from ECR
# - Write logs to CloudWatch
##############################################

resource "aws_iam_role" "sagemaker" {
  name = "${var.project_name}-sagemaker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "sagemaker.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach AWS managed policy (broad permissions)
resource "aws_iam_role_policy_attachment" "sagemaker_policy" {
  role       = aws_iam_role.sagemaker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

##############################################
# Lambda Execution Role
##############################################
# This role allows Lambda to:
# - Write logs
# - Invoke SageMaker endpoint
##############################################

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Basic logging permissions
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy to allow invoking SageMaker endpoint
resource "aws_iam_role_policy" "lambda_sagemaker" {
  name = "invoke-sagemaker"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sagemaker:InvokeEndpoint",
      Resource = "*"
    }]
  })
}

##############################################
# Outputs
##############################################

output "sagemaker_role_arn" {
  value = aws_iam_role.sagemaker.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda.arn
}
