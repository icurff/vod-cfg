# ══════════════════════════════════════════════
# StreamForge — Root Module Composition (AWS)
# ══════════════════════════════════════════════
# Usage:
#   terraform init
#   terraform plan  -var-file=environments/dev.tfvars
#   terraform apply -var-file=environments/dev.tfvars

locals {
  tags = {
    Environment = var.environment
    Project     = "StreamForge"
    ManagedBy   = "Terraform"
  }

  s3_bucket_name = "streamforge-media-${var.environment}-${var.aws_account_id}"
}

# 1. VPC & Networking (no NAT Gateway — VPC Endpoints handle AWS services)
module "vpc" {
  source = "./modules/vpc"

  environment = var.environment
  tags        = local.tags
}

# 2. VPC Endpoints — keep all AWS API traffic inside the AWS backbone
#    S3 (Gateway, free) + SQS/ECR/SecretsManager/CloudWatch/EKS (Interface)
module "vpc_endpoints" {
  source = "./modules/vpc_endpoints"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.public_subnet_ids
  route_table_ids    = [module.vpc.public_route_table_id, module.vpc.private_route_table_ids[0]]
  eks_node_sg_id     = module.eks.node_security_group_id
  environment        = var.environment
  aws_region         = var.aws_region
  tags               = local.tags
}

# 3. EKS Cluster (private nodes, spot node group for workers)
module "eks" {
  source = "./modules/eks"

  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.public_subnet_ids
  public_subnet_ids    = module.vpc.public_subnet_ids
  environment          = var.environment
  cluster_name         = var.eks_cluster_name
  kubernetes_version   = var.kubernetes_version
  system_instance_type = var.eks_system_instance_type
  system_node_count    = var.eks_system_count
  spot_instance_types  = var.eks_spot_instance_types
  spot_max_count       = var.eks_spot_max_count
  tags                 = local.tags
}

# 4. ECR Repositories (backend, frontend, worker)
module "ecr" {
  source = "./modules/ecr"

  environment       = var.environment
  eks_node_role_arn = module.eks.node_role_arn
  tags              = local.tags
}

# 5. S3 Media Bucket (private, served via CloudFront OAC)
module "s3" {
  source = "./modules/s3"

  bucket_name   = local.s3_bucket_name
  environment   = var.environment
  force_destroy = var.s3_force_destroy
  tags          = local.tags
}

# 6. DynamoDB Tables (Serverless, 100% Free tier compatible)
module "dynamodb" {
  source = "./modules/dynamodb"

  environment = var.environment
  tags        = local.tags
}

# 7. SQS Queue (transcode job queue)
module "sqs" {
  source = "./modules/sqs"

  environment   = var.environment
  s3_bucket_arn = module.s3.bucket_arn
  tags          = local.tags
}

# 8. S3 → SQS Event Notifications (trigger transcode on upload)
module "s3_notifications" {
  source = "./modules/s3_notifications"

  bucket_id     = module.s3.bucket_id
  sqs_queue_arn = module.sqs.queue_arn
}

# 9. Secrets Manager (MongoDB connection string for Backend and Worker)
module "secrets_manager" {
  source = "./modules/secrets_manager"

  environment           = var.environment
  documentdb_uri        = var.custom_mongodb_uri
  backend_irsa_role_arn = module.iam_irsa.backend_role_arn
  worker_irsa_role_arn  = module.iam_irsa.worker_role_arn
  tags                  = local.tags
}

# 10. CloudWatch (log groups for EKS workloads)
module "cloudwatch" {
  source = "./modules/cloudwatch"

  environment = var.environment
  tags        = local.tags
}

# 11. CloudFront (media CDN via OAC + frontend distribution)
module "cloudfront" {
  source = "./modules/cloudfront"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  s3_bucket_regional_domain = module.s3.bucket_regional_domain_name
  s3_bucket_id              = module.s3.bucket_id
  frontend_domain           = var.frontend_domain
  api_domain                = var.api_domain
  media_domain              = var.media_domain
  enable_custom_domain      = var.enable_custom_domain
  environment               = var.environment
  tags                      = local.tags
}

# 12. IAM IRSA Roles (pod-level AWS permissions, no long-lived keys)
module "iam_irsa" {
  source = "./modules/iam_irsa"

  environment       = var.environment
  aws_account_id    = var.aws_account_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  s3_bucket_arn     = module.s3.bucket_arn
  sqs_queue_arn     = module.sqs.queue_arn
  tags              = local.tags
}

# S3 Bucket Policy — allow only CloudFront OAC (separate to avoid circular dep)
resource "aws_s3_bucket_policy" "media" {
  bucket = module.s3.bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${module.s3.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.media_distribution_arn
          }
        }
      }
    ]
  })
}
