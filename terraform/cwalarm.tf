resource "aws_sns_topic" "alarm_sns" {
  name = var.alarm_sns_name
  
  tags = {
    environment = "dev"
    app = "alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "webapp-availability-alarm" {
  alarm_name                = "dev-webapp-availability"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "1"
  metric_name               = var.metric_name
  namespace                 = var.metric_namespace
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "1"
  alarm_description         = "Webapp availability alarm"
  alarm_actions             = [resource.aws_sns_topic.alarm_sns.arn]
  insufficient_data_actions = []
  dimensions = {
    InstanceId  =  var.ec2_instanceid
  }

  depends_on = [
    resource.aws_sns_topic.alarm_sns
  ]
}
