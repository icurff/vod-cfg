variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "public_subnet_ids" { type = list(string) }
variable "environment" { type = string }

variable "cluster_name" {
  type        = string
  description = "EKS cluster name (shared across environments)"
  default     = "eks-streamforge"
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "system_instance_type" { type = string }
variable "system_node_count" { type = number }
variable "spot_instance_types" { type = list(string) }
variable "spot_max_count" { type = number }
variable "tags" { type = map(string) }
