
# Lambda de crop
resource "aws_lambda_function" "crop_lambda" {
  function_name    = "crop-lambda-${terraform.workspace}"
  role             = aws_iam_role.crop_lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  memory_size      = 512
  timeout          = 60
  filename         = data.archive_file.crop_zip.output_path
  source_code_hash = data.archive_file.crop_zip.output_base64sha256

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg_crop.id]
  }

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.id
      PROCESSED_PREFIX = "processed/"
    }
  }

  depends_on = [
    aws_iam_role_policy.crop_policy
  ]
}

# Path del codigo
data "archive_file" "crop_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/lambdas/crop"
  output_path = "${path.module}/crop_function.zip"
}

# Trigger de sqs
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn        = aws_sqs_queue.image_queue.arn
  function_name           = aws_lambda_function.crop_lambda.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]
}

# Logs de la lambda
resource "aws_cloudwatch_log_group" "crop_logs" {
  name              = "/aws/lambda/${aws_lambda_function.crop_lambda.function_name}"
  retention_in_days = 14
}