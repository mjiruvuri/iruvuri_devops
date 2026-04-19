output "jenkins_public_ip" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins UI URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "instance_id" {
  description = "EC2 instance ID (use for SSM Session Manager)"
  value       = aws_instance.jenkins.id
}

output "iam_role_arn" {
  description = "ARN of the Jenkins IAM role"
  value       = aws_iam_role.jenkins.arn
}

output "security_group_id" {
  description = "Jenkins EC2 security group ID"
  value       = aws_security_group.jenkins.id
}
