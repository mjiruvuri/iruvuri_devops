output "instance_public_ips" {
  description = "Public IP addresses of the EC2 instances"
  value       = [for i in aws_instance.this : i.public_ip]
}

output "instance_public_dns" {
  description = "Public DNS names of the EC2 instances"
  value       = [for i in aws_instance.this : i.public_dns]
}
output "instance_private_ips" {
  description = "Private IP addresses of the EC2 instances"
  value       = [for i in aws_instance.this : i.private_ip]
}
