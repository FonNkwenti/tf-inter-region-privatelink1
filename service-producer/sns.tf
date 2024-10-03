resource "aws_sns_topic" "asg_events" {
  name = "asg-events"

  provider = aws.service_provider_main
}

resource "aws_autoscaling_notification" "application_asg_notifications" {
  group_names = [
    aws_autoscaling_group.application.name,
  ]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]
  topic_arn = aws_sns_topic.asg_events.arn

  provider = aws.service_provider_main
}