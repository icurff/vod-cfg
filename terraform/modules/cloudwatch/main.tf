resource "aws_cloudwatch_log_group" "backend" {
  name              = "/streamforge/${var.environment}/backend"
  retention_in_days = var.environment == "production" ? 30 : 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/streamforge/${var.environment}/frontend"
  retention_in_days = var.environment == "production" ? 30 : 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/streamforge/${var.environment}/transcode-worker"
  retention_in_days = var.environment == "production" ? 30 : 14
  tags              = var.tags
}
