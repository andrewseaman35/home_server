terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "notification_topic" {
  name = "${var.environment}-${var.project_name}-notifications"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Create IAM user for the service
resource "aws_iam_user" "service_user" {
  name = "${var.environment}-${var.project_name}-service-user"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Create access keys for the IAM user
resource "aws_iam_access_key" "service_user_key" {
  user = aws_iam_user.service_user.name
}

# Create IAM policy for SNS publish permissions
resource "aws_iam_policy" "sns_publish_policy" {
  name        = "${var.environment}-${var.project_name}-sns-publish"
  description = "Allow publishing to SNS topic"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.notification_topic.arn
        ]
      }
    ]
  })
}

# Attach the policy to the user
resource "aws_iam_user_policy_attachment" "service_user_policy" {
  user       = aws_iam_user.service_user.name
  policy_arn = aws_iam_policy.sns_publish_policy.arn
}

# Optional: Add an SNS topic policy to restrict access
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.notification_topic.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPublishFromOwnAccount"
        Effect = "Allow"
        Principal = {
          AWS = [
            data.aws_caller_identity.current.account_id,
            aws_iam_user.service_user.arn
          ]
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.notification_topic.arn
      }
    ]
  })
}