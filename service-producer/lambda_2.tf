resource "aws_iam_role" "lambda_role" {
  name = "lambda_nlb_target_updater_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  provider = aws.service_provider_region
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_nlb_target_updater_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "autoscaling:DescribeAutoScalingGroups",
          "ec2:DescribeInstances",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })

  provider = aws.service_provider_region
}

// https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AWSLambdaBasicExecutionRole.html

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

  provider   = aws.service_provider_region

}
// https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEC2ReadOnlyAccess.html
resource "aws_iam_role_policy_attachment" "ec2_read" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"

  provider   = aws.service_provider_region

}

data "archive_file" "get_handler_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/"
  output_path = "${path.module}/src/archives/get.zip"

}
# data "archive_file" "get_handler_zip" {
#   type        = "zip"
#   source_dir = "${path.module}/src/handlers/"
#   output_path = "${path.module}/src/archives/get.zip"
# }

resource "aws_lambda_function" "nlb_target_updater" {
  filename         = data.archive_file.get_handler_zip.output_path
  function_name    = "nlb_target_updater"
  role             = aws_iam_role.lambda_role.arn
  handler          = "getIps.handler"
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      =  128
  source_code_hash = data.archive_file.get_handler_zip.output_base64sha256
  # source_code_hash = data.archive_file.get_handler_zip.output_base64sha256

  logging_config {
    log_format = "Text"
  }

  environment {
    variables = {
      TARGET_GROUP_ARN = aws_lb_target_group.region_private_nlb_tg.arn
      ASG_NAME         = aws_autoscaling_group.application.name
      ASG_TAG          = local.instance_name
    }
  }

  provider = aws.service_provider_region
}

resource "aws_cloudwatch_log_group" "getIps" {
  name              = "/aws/lambda/${aws_lambda_function.nlb_target_updater.function_name}"
  retention_in_days = 5

  provider = aws.service_provider_region
}



