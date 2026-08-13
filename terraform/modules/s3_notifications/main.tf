# S3 → SQS event notification: trigger transcode on video upload
resource "aws_s3_bucket_notification" "transcode_trigger" {
  bucket = var.bucket_id

  queue {
    queue_arn     = var.sqs_queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
    # filter_suffix = ".mp4"  # uncomment to restrict to MP4 uploads only
  }
}
