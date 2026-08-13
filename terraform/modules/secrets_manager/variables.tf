variable "environment"           { type = string }
variable "backend_irsa_role_arn" { type = string }
variable "worker_irsa_role_arn"  { type = string }
variable "tags"                  { type = map(string) }

variable "documentdb_uri" {
  type      = string
  sensitive = true
}
