output "videos_table_name" { value = aws_dynamodb_table.videos.name }
output "videos_table_arn"  { value = aws_dynamodb_table.videos.arn }

output "users_table_name" { value = aws_dynamodb_table.users.name }
output "users_table_arn"  { value = aws_dynamodb_table.users.arn }
