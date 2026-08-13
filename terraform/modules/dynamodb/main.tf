# ── Minimal & Fast DynamoDB Tables (No GSI bottlenecks, 100% Free Tier) ──

# 1. Videos Table (Core for Upload & Streaming)
resource "aws_dynamodb_table" "videos" {
  name         = "streamforge-videos-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = var.tags
}

# 2. Users Table (Authentication & User Profile)
resource "aws_dynamodb_table" "users" {
  name         = "streamforge-users-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = var.tags
}
