variable "environment"       { type = string }
variable "aws_account_id"    { type = string }
variable "oidc_provider_arn" { type = string }
variable "oidc_provider_url" { type = string }
variable "s3_bucket_arn"     { type = string }
variable "sqs_queue_arn"     { type = string }
variable "tags"              { type = map(string) }
