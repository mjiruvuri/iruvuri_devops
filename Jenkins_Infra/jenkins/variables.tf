variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name"
}

variable "admin_cidr" {
  type        = string
  description = "Your public IP in CIDR format, for example 203.0.113.10/32"
}

variable "root_volume_size" {
  type    = number
  default = 30
}