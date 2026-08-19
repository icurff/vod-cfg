variable "bucket_name" { type = string }
variable "environment" { type = string }

variable "force_destroy" {
  type    = bool
  default = false
}

variable "tags" { type = map(string) }
