
# Configuración central del api gateway
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-${terraform.workspace}"
  protocol_type = "HTTP"

  # Cors configuration
  cors_configuration {
    allow_origins = ["*"] 
    allow_methods = ["POST", "OPTIONS"] 
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }
}


# Protocol format 2.0
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.upload_lambda.invoke_arn 
  payload_format_version = "2.0" 
}


# Route para POST /upload
resource "aws_apigatewayv2_route" "upload_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}


# STAGE 
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  # Configuración del Throttling
  default_route_settings {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }

  # Access logs para Cloudwatch
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format          = jsonencode({
      requestId      = "$context.requestId"
      sourceIp       = "$context.identity.sourceIp"
      protocol       = "$context.protocol"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      error          = "$context.authorizer.error"
    })
  }
}

# Log group

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "/aws/apigateway/${var.project_name}-${terraform.workspace}"
  retention_in_days = 14
}