# ── AWS Identity ──
variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-1"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
  default     = "393698973321"
}

# ── General ──
variable "environment" {
  type        = string
  description = "Environment name: dev, staging, production"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for EKS cluster"
  default     = "1.34"
}

variable "eks_cluster_name" {
  type        = string
  description = "Shared EKS cluster name across environments"
  default     = "eks-streamforge"
}

# ── EKS System Node Group ──
variable "eks_system_instance_type" {
  type        = string
  description = "EC2 instance type for system node pool (t3.small Free Tier eligible)"
  default     = "t3.small"
}

variable "eks_system_count" {
  type        = number
  description = "Number of system nodes"
  default     = 1
}

# ── EKS Spot Node Group (Transcode Workers) ──
variable "eks_spot_instance_types" {
  type        = list(string)
  description = "EC2 instance types for spot node pool"
  default     = ["t3.small"]
}

variable "eks_spot_max_count" {
  type        = number
  description = "Max spot nodes for scale-out during heavy transcode"
  default     = 3
}

# ── Database ──
variable "custom_mongodb_uri" {
  type        = string
  description = "MongoDB URI for backend and worker"
  default     = "mongodb://mongodb.streamforge.svc.cluster.local:27017/streamforge"
  sensitive   = true
}

# ── S3 ──
variable "s3_force_destroy" {
  type        = bool
  description = "Allow terraform destroy to delete non-empty S3 bucket (use only in dev)"
  default     = false
}

# ── Domain ──
variable "frontend_domain" {
  type    = string
  default = "icurff.site"
}

variable "api_domain" {
  type    = string
  default = "api.icurff.site"
}

variable "media_domain" {
  type    = string
  default = "media.icurff.site"
}

variable "enable_custom_domain" {
  type        = bool
  description = "Set to true after ACM certificate DNS validation is complete to attach custom domains to CloudFront"
  default     = false
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name from NGINX Ingress controller"
  default     = ""
}

# ── GitHub ──
variable "github_repo" {
  type        = string
  description = "GitHub repo in format 'owner/repo'"
  default     = "icurff/streamforge"
}
