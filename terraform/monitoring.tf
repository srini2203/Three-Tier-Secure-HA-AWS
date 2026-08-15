#############################################
# Monitoring — CloudWatch alarms + SNS
#############################################

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email

  # AWS emails a confirmation link to notification_email after apply —
  # the subscription stays PendingConfirmation until it's clicked.
}

resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
  alarm_name          = "${var.project_name}-asg-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Average CPU across the ASG has been above 80% for 10 minutes"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-asg-high-cpu"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.project_name}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU has been above 80% for 10 minutes"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-rds-high-cpu"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${var.project_name}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648 # 2 GiB, in bytes
  alarm_description   = "RDS free storage has dropped below 2 GiB"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-rds-low-storage"
  }
}