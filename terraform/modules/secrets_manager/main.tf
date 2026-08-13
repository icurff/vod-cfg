# DocumentDB URI secret — accessible only by backend and worker IRSA roles
resource "aws_secretsmanager_secret" "docdb_uri" {
  name                    = "streamforge/${var.environment}/documentdb-uri"
  description             = "DocumentDB MongoDB connection string for StreamForge ${var.environment}"
  recovery_window_in_days = 0 # immediate deletion (change to 7 for production)
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "docdb_uri" {
  secret_id     = aws_secretsmanager_secret.docdb_uri.id
  secret_string = var.documentdb_uri
}

# Resource policy: only IRSA roles of backend + worker can read this secret
resource "aws_secretsmanager_secret_policy" "docdb_uri" {
  secret_arn = aws_secretsmanager_secret.docdb_uri.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowIRSARoles"
        Effect = "Allow"
        Principal = {
          AWS = [
            var.backend_irsa_role_arn,
            var.worker_irsa_role_arn,
          ]
        }
        Action   = "secretsmanager:GetSecretValue"
        Resource = "*"
      }
    ]
  })
}
