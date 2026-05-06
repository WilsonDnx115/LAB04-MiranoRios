# Cola para mensajes fallidos
resource "aws_sqs_queue" "image_dlq" {
  name                      = "image-processor-${terraform.workspace}-image-dlq"
  message_retention_seconds = 1209600 
}

# Topic para notificaciones de error
resource "aws_sns_topic" "dlq_alarm_topic" {
  name = "dlq-alarm-${terraform.workspace}-topic"
}

# Suscripcion para recibir alertas al correo
resource "aws_sns_topic_subscription" "dlq_email" {
  topic_arn = aws_sns_topic.dlq_alarm_topic.arn
  protocol  = "email"
  endpoint  = "wilsondanix@gmail.com" 
}

# Alarma que vigila si hay algo en la dlq
resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "dlq-messages-${terraform.workspace}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "se dispara si hay mensajes estancados en la dlq"

  dimensions = {
    QueueName = aws_sqs_queue.image_dlq.name
  }

  alarm_actions = [aws_sns_topic.dlq_alarm_topic.arn]
}
