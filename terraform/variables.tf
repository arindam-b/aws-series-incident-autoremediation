variable "aws_account_number" {
  default = ""
  description = "AWS Account number 12 digits"
}

variable "region" {
  default = "us-east-1"
  description = "AWS Region where the resources will be created"
}

variable "app_name" {
  default = "my-autoremediation-app"
  description = "Description of the application"
}

variable "env" {
  default = "dev"
  description = "environment name"
}

variable "lambda_name" {
  default = "tekincloud-dev-autoremediation"
  description = "role name of the aws lambda"
}

variable "policy_name" {
  default = "autoremediation-policy"
  description = "policy name of the aws lambda"
}

variable "policy_description" {
  default = "autoremediation iam policy"
  description = "policy autoremediation"
}

variable "lambda_role" {
  default = "autoremediation-role"
  description = "role name of the aws lambda"
}

variable "ec2_instanceid" {
  default = ""
  description = "ec2 instance-id for which cloudwatch alarm to be created"
}

variable "alarm_sns_name" {
  default = "alarm-sns"
  description = "alarm sns"
}

variable "cw_scheduled_event_rule_lambda" {
  default = "alarm-trigger-autoremediation"
  description = "alarm trigger autoremediation"
}

variable "cw_scheduled_event_rule_lambda_description" {
  default = "alarm trigger autoremediation process invoking lambda"
  description = "alarm trigger autoremediation trigger"
}

variable "bucket_name" {
  default = ""
  description = "The auto remediation config storage "
}

variable "metric_namespace" {
  default = "AWS/EC2"
  description = "Metric namespace"
}

variable "metric_name" {
  default = ""
  description = "Metric name"
}
