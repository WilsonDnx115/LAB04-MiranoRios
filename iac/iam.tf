# Role para lambda de upload
resource "aws_iam_role" "upload_lambda_role" {
  name = "${var.project_name}-${terraform.workspace}-upload-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Policy de upload: s3 y logs
resource "aws_iam_role_policy" "upload_policy" {
  name = "upload-limited-policy"
  role = aws_iam_role.upload_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = ["${aws_s3_bucket.images.arn}/uploads/*"]
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents",
          "ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"
        ]
        Resource = ["*"]
      }
    ]
  })
}


# Role para lambda de crop
resource "aws_iam_role" "crop_lambda_role" {
  name = "${var.project_name}-${terraform.workspace}-crop-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { 
        Service = "lambda.amazonaws.com" }
    }]
  })
}


# Policy de crop: s3, sqs y logs
resource "aws_iam_role_policy" "crop_policy" {
  name = "crop-limited-policy"
  role = aws_iam_role.crop_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3: Get de uploads y Put en processed
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.images.arn}/uploads/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = ["${aws_s3_bucket.images.arn}/processed/*"]
      },
      # SQS: Permisos exactos del diagrama
      {
        Effect   = "Allow"
        Action   = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = [aws_sqs_queue.image_queue.arn]
      },
      # Logs y VPC
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents",
          "ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# Role para logs de api gateway
resource "aws_iam_role" "api_gw_cloudwatch" {
  name = "${var.project_name}-${terraform.workspace}-api-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gw_cloudwatch_policy" {
  role       = aws_iam_role.api_gw_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}