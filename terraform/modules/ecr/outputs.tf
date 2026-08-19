output "backend_repository_url" { value = aws_ecr_repository.repos["streamforge-backend"].repository_url }
output "frontend_repository_url" { value = aws_ecr_repository.repos["streamforge-frontend"].repository_url }
output "worker_repository_url" { value = aws_ecr_repository.repos["streamforge-worker"].repository_url }
