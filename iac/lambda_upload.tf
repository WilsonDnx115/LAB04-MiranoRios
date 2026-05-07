
# Lambda de upload
resource "aws_lambda_function" "upload_lambda" {
  function_name    = "upload-lambda-${terraform.workspace}"
  role             = aws_iam_role.upload_lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  memory_size      = 256
  timeout          = 30
  filename         = data.archive_file.upload_zip.output_path
  source_code_hash = data.archive_file.upload_zip.output_base64sha256

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg_upload.id]
  }

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.images.id
      UPLOAD_PREFIX = "uploads/"
    }
  }

  depends_on = [
    aws_iam_role_policy.upload_policy
  ]
}

# Path del codigo
data "archive_file" "upload_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/lambdas/upload"
  output_path = "${path.module}/upload_function.zip"
}

# Permisos para apigateway
resource "aws_lambda_permission" "apigw_upload" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

# Logs de la lambda
resource "aws_cloudwatch_log_group" "upload_logs" {
  name              = "/aws/lambda/${aws_lambda_function.upload_lambda.function_name}"
  retention_in_days = 14
}