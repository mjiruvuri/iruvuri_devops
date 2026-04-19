variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-lab"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "node_instance_types" {
  description = "Spot instance types for the node group (multiple for availability)"
  type        = list(string)
  default     = ["t3.medium", "t3.large", "t3a.medium"]
}

variable "node_desired" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "jenkins_sg_id" {
  description = "Jenkins EC2 security group ID — allowed to reach EKS API on port 443"
  type        = string
  default     = ""
}
