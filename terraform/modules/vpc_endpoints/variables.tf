variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "route_table_ids"    { type = list(string) }
variable "eks_node_sg_id"     { type = string }
variable "environment"        { type = string }
variable "aws_region"         { type = string }
variable "tags"               { type = map(string) }
