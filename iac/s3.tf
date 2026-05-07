# Bucket principal
resource "aws_s3_bucket" "images" {
  bucket        = replace(lower("${var.project_name}-storage-${terraform.workspace}"), "_", "-")
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-bucket-${terraform.workspace}"
    Environment = terraform.workspace
    Project     = var.project_name
  }
}

# Carpetas S3
resource "aws_s3_object" "uploads_folder" {
  bucket = aws_s3_bucket.images.id
  key    = "uploads/" 
}

resource "aws_s3_object" "processed_folder" {
  bucket = aws_s3_bucket.images.id
  key    = "processed/" 
}

# Cifrado SSE
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.images.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" 
    }
  }
}

# Versionamiento
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.images.id
  versioning_configuration {
    status = "Enabled" 
  }
}

# Ciclo de vida
resource "aws_s3_bucket_lifecycle_configuration" "images_lifecycle" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "expire-original-images"
    status = "Enabled"
    filter {
      prefix = "uploads/" 
    }
    expiration {
      days = 30 
    }
  }

  rule {
    id     = "expire-processed-images"
    status = "Enabled"
    filter {
      prefix = "processed/" 
    }
    expiration {
      days = 90 
    }
  }
}

# Acceso privado
resource "aws_s3_bucket_public_access_block" "images_access" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Notificaciones a SQS
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.images.id

  queue {
    queue_arn     = aws_sqs_queue.image_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/" 
  }

  depends_on = [aws_sqs_queue_policy.image_queue_policy]
}
