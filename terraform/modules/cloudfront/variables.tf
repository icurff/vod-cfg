variable "s3_bucket_regional_domain" { type = string }
variable "s3_bucket_id" { type = string }
variable "frontend_domain" { type = string }
variable "api_domain" { type = string }
variable "media_domain" { type = string }
variable "environment" { type = string }

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name — set after NGINX Ingress is deployed via Helm"
  default     = ""
}

variable "enable_custom_domain" {
  type        = bool
  description = "Attach custom domain and ACM certificate to CloudFront (enable after ACM cert validation is complete)"
  default     = false
}

variable "tags" { type = map(string) }
