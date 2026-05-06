
# sg para lambda de upload
resource "aws_security_group" "lambda_sg_upload" {
  name        = "${var.project_name}-${terraform.workspace}-upload-sg"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# sg para lambda de crop
resource "aws_security_group" "lambda_sg_crop" {
  name        = "${var.project_name}-${terraform.workspace}-crop-sg"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# sg para endpoint de sqs
resource "aws_security_group" "sqs_endpoint_sg" {
  name        = "${var.project_name}-${terraform.workspace}-sqs-vpce-sg"
  description = "Permite trafico HTTPS hacia el endpoint de SQS desde las Lambdas"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [
      aws_security_group.lambda_sg_upload.id, 
      aws_security_group.lambda_sg_crop.id    
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${terraform.workspace}-sqs-vpce-sg" }
}