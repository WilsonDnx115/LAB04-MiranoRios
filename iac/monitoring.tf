# topic para alarmas
resource "aws_sns_topic" "dlq_alarm_topic" {
  name = "dlq_alarm-${terraform.workspace}-topic"
}

# correo para avisar
resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn            = aws_sns_topic.dlq_alarm_topic.arn
  protocol             = "email"
  endpoint             = "wilsondanix@gmail.com"
}

# alarma si hay mensajes en dlq
resource "aws_cloudwatch_metric_alarm" "dql_messages_alarm" {
  alarm_name                = "dql_messages_alarm-${terraform.workspace}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "ApproximateNumberOfMessagesVisible"
  namespace                 = "AWS/SQS"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 0
  alarm_description         = "Esta alarma se dispara si hay mensajes estancados en la DLQ"

  dimensions = {
    QueueName = aws_sqs_queue.image_dlq.name
  }

  alarm_actions = [aws_sns_topic.dlq_alarm_topic.arn]
}
