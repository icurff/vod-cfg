output "secret_arn"  { value = aws_secretsmanager_secret.docdb_uri.arn }
output "secret_name" { value = aws_secretsmanager_secret.docdb_uri.name }
