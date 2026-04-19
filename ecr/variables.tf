variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["app", "jenkins-agent"]
}

variable "image_retention_count" {
  description = "Number of images to keep per repository (older ones are deleted)"
  type        = number
  default     = 10
}
