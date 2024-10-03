


resource "aws_iam_role" "eventbridge_role" {
  name = "eventbridge-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
    provider = aws.service_provider_region
}

resource "aws_iam_policy_attachment" "eventbridge_exec" {
  name       = "eventbridge-exec-policy-attachment"
  roles      = [aws_iam_role.eventbridge_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
    provider = aws.service_provider_region
}


# EventBridge Rule
resource "aws_cloudwatch_event_rule" "asg_change" {
  name        = "asg-instance-change"
  description = "Capture changes in ASG instances"

  event_pattern = jsonencode({
    source = ["aws.autoscaling"]
    detail-type = [
      "EC2 Instance Launch Successful",
      "EC2 Instance Terminate Successful"
    ]
    detail = {
      AutoScalingGroupName = [aws_autoscaling_group.application.name]
    }
  })

  provider = aws.service_provider_region
}

resource "aws_cloudwatch_event_target" "asg_change" {
  arn  = aws_lambda_function.nlb_target_updater.arn
  rule = aws_cloudwatch_event_rule.asg_change.name

  provider = aws.service_provider_region
}

resource "aws_lambda_permission" "nlb_target_updater" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nlb_target_updater.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_change.arn

  provider = aws.service_provider_region
}


# # EventBridge Target
# resource "aws_cloudwatch_event_target" "lambda" {
#   rule      = aws_cloudwatch_event_rule.asg_change.name
#   target_id = "TriggerLambda"
#   arn       = aws_lambda_function.nlb_target_updater.arn
# }

# # Lambda Permission for EventBridge
# resource "aws_lambda_permission" "allow_eventbridge" {
#   statement_id  = "AllowExecutionFromEventBridge"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.nlb_target_updater.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.asg_change.arn
# }


### Cron Job test

# resource "aws_cloudwatch_event_rule" "getIps_lambda_event_rule" {
#   name                = "cron-lambda-event-rule"
#   description         = "invoke scheduled every 2 min"
#   schedule_expression = "rate(5 minutes)"

#   provider = aws.service_provider_region
# }

# resource "aws_cloudwatch_event_target" "getIps_lambda_target" {
#   arn  = aws_lambda_function.nlb_target_updater.arn
#   rule = aws_cloudwatch_event_rule.getIps_lambda_event_rule.name

#   provider = aws.service_provider_region
# }



# resource "aws_scheduler_schedule" "invoke_lambda_schedule" {
#   name = "inkoke-lambda-schedule"
#   flexible_time_window {
#     mode = "OFF"
#   }
#   schedule_expression = "rate(5 minute)"
#   target {
#     arn = aws_lambda_function.nlb_target_updater.arn
#     role_arn = aws_iam_role.eventbridge_role.arn
#     input = jsonencode({"input": "This message was sent using EventBridge Scheduler!"})
#   }

#     provider = aws.service_provider_region
# }