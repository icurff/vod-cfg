# ── EKS ──
output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name — use with: aws eks update-kubeconfig --name <value>"
}

output "eks_cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}

# ── ECR ──
output "ecr_registry_url" {
  value       = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  description = "ECR registry base URL"
}

output "ecr_backend_url" {
  value = module.ecr.backend_repository_url
}

output "ecr_frontend_url" {
  value = module.ecr.frontend_repository_url
}

output "ecr_worker_url" {
  value = module.ecr.worker_repository_url
}

# ── S3 ──
output "s3_bucket_name" {
  value       = module.s3.bucket_id
  description = "S3 media bucket name"
}

output "s3_bucket_arn" {
  value = module.s3.bucket_arn
}

# ── DynamoDB ──
output "dynamodb_videos_table" {
  value = module.dynamodb.videos_table_name
}

output "documentdb_connection_string" {
  value       = var.custom_mongodb_uri
  sensitive   = true
  description = "MongoDB URI for backend and transcode worker (stored in Secrets Manager)"
}

# ── SQS ──
output "sqs_queue_url" {
  value       = module.sqs.queue_url
  sensitive   = true
  description = "SQS queue URL for transcode worker"
}

output "sqs_queue_arn" {
  value = module.sqs.queue_arn
}

# ── CloudFront & ACM ──
output "cloudfront_media_domain" {
  value       = module.cloudfront.media_distribution_domain
  description = "Point media.icurff.site CNAME to this value"
}

output "cloudfront_frontend_domain" {
  value       = module.cloudfront.frontend_distribution_domain
  description = "Point icurff.site CNAME to this value"
}

output "acm_certificate_arn" {
  value       = module.cloudfront.acm_certificate_arn
  description = "ACM Certificate ARN (in us-east-1)"
}

output "acm_validation_records" {
  value       = module.cloudfront.acm_validation_records
  description = "DNS CNAME records to validate the ACM certificate"
}


# ── IAM IRSA ──
output "backend_irsa_role_arn" {
  value       = module.iam_irsa.backend_role_arn
  description = "Annotate backend ServiceAccount with this ARN"
}

output "worker_irsa_role_arn" {
  value       = module.iam_irsa.worker_role_arn
  description = "Annotate transcode-worker ServiceAccount with this ARN"
}
