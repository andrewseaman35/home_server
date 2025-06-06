output "sns_topic_arn" {
  description = "ARN of the created SNS topic"
  value       = aws_sns_topic.notification_topic.arn
}

output "sns_topic_name" {
  description = "Name of the created SNS topic"
  value       = aws_sns_topic.notification_topic.name
}

output "service_user_name" {
  description = "Name of the IAM user for the service"
  value       = aws_iam_user.service_user.name
}

output "service_user_arn" {
  description = "ARN of the IAM user for the service"
  value       = aws_iam_user.service_user.arn
}

output "service_user_access_key_id" {
  description = "Access key ID for the service user"
  value       = aws_iam_access_key.service_user_key.id
}

output "service_user_secret_access_key" {
  description = "Secret access key for the service user"
  value       = aws_iam_access_key.service_user_key.secret
  sensitive   = true
}

output "aws_region" {
  description = "AWS region used for the resources"
  value       = var.aws_region
}