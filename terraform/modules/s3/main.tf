# S3 media bucket — private, served only via CloudFront OAC
resource "aws_s3_bucket" "media" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block ALL public access — only CloudFront OAC reads this bucket
resource "aws_s3_bucket_public_access_block" "media" {
  bucket                  = aws_s3_bucket.media.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS: allow CloudFront edge locations to serve HLS to browsers
resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://icurff.site", "https://*.icurff.site"]
    expose_headers  = ["ETag", "Content-Length"]
    max_age_seconds = 3000
  }
}

# Create logical folder prefixes
resource "aws_s3_object" "uploads_prefix" {
  bucket  = aws_s3_bucket.media.id
  key     = "uploads/"
  content = ""
}

resource "aws_s3_object" "hls_prefix" {
  bucket  = aws_s3_bucket.media.id
  key     = "hls/"
  content = ""
}
