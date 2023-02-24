# Allow the SNS topic to invoke the Lambda
resource "aws_lambda_permission" "allow_invocation_from_sns" {
  # Once lambda is created then only this event sourcing will be done
  depends_on = [
    module.autoremediation_lambda_function,
    resource.aws_cloudwatch_metric_alarm.webapp-availability-alarm
  ]   

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "sns.amazonaws.com"
  source_arn    = resource.aws_sns_topic.alarm_sns.arn
}

# Lambda event sourcing from SNS topic
resource "aws_sns_topic_subscription" "lambda_sns_event_sourcing_subscription" {
  # Once lambda is created then only this event sourcing will be done
  depends_on = [
    module.autoremediation_lambda_function,
    resource.aws_cloudwatch_metric_alarm.webapp-availability-alarm
  ]    

  # Auto remediation sns
  topic_arn = resource.aws_sns_topic.alarm_sns.arn
  protocol  = "lambda"

  # Lambda function
  endpoint  = module.autoremediation_lambda_function.lambda_function_arn
}

