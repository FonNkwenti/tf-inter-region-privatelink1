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

resource "aws_lambda_function" "nlb_target_updater" {
  filename      = "lambda_function.zip"
  function_name = "nlb_target_updater"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  environment {
    variables = {
      TARGET_GROUP_ARN = aws_lb_target_group.region_private_nlb_tg.arn
      ASG_NAME         = aws_autoscaling_group.application.name
    }
  }
    provider = aws.service_provider_region
}