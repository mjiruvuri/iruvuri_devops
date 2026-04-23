variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.medium"
}

variable "spot_max_price" {
  description = "Maximum Spot price per hour (leave empty to use on-demand price as cap)"
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID for the selected region"
  type        = string
}

variable "allowed_cidr" {
  description = "Your IP in CIDR notation allowed to reach Jenkins UI and SSH (e.g. 1.2.3.4/32)"
  type        = string
}

variable "state_bucket_name" {
  description = "S3 bucket name used for Terraform remote state (for Jenkins IAM policy)"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name used for Terraform state locking"
  type        = string
  default     = "terraform-locks"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access (optional — use SSM Session Manager if empty)"
  type        = string
  default     = null
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "jenkins_data_volume_size_gb" {
  description = "Persistent EBS volume size in GB for Jenkins data (survives spot termination)"
  type        = number
  default     = 30
}

variable "jenkins_data_volume_az" {
  description = "AZ for the persistent Jenkins data EBS volume — must match the EC2 instance AZ"
  type        = string
}
