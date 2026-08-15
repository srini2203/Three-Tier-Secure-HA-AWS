output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}

output "alb_dns_name" {
  description = "Public DNS name of the load balancer — hit this over HTTP to reach the app"
  value       = aws_lb.app.dns_name
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "db_instance_endpoint" {
  description = "RDS connection endpoint (private — only reachable from within the VPC)"
  value       = aws_db_instance.this.endpoint
}

output "secrets_manager_secret_arn" {
  description = "ARN of the secret holding DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic CloudWatch alarms publish to"
  value       = aws_sns_topic.alerts.arn
}