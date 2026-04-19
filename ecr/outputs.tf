output "repository_urls" {
  description = "ECR repository URLs keyed by name"
  value       = { for k, v in aws_ecr_repository.repos : k => v.repository_url }
}

output "registry_id" {
  description = "ECR registry ID (your AWS account ID)"
  value       = values(aws_ecr_repository.repos)[0].registry_id
}

output "docker_login_command" {
  description = "Run this to authenticate Docker with ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${values(aws_ecr_repository.repos)[0].registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}
