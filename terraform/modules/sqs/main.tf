# ── SQS Queue ──
resource "aws_sqs_queue" "transcode" {
  name                       = "streamforge-transcode-queue-${var.environment}"
  visibility_timeout_seconds = 300    # 5 minutes — enough for long transcodes
  message_retention_seconds  = 345600 # 4 days
  receive_wait_time_seconds  = 20     # long polling (reduces empty receive cost)
  sqs_managed_sse_enabled    = true   # server-side encryption
  tags                       = var.tags
}

# ── Queue Policy: allow S3 bucket to send messages + EKS IRSA to consume ──
resource "aws_sqs_queue_policy" "transcode" {
  queue_url = aws_sqs_queue.transcode.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3SendMessage"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.transcode.arn
        Condition = {
          ArnLike = { "aws:SourceArn" = var.s3_bucket_arn }
        }
      }
    ]
  })
}
