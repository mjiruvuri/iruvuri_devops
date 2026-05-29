variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "Resource group for the AKS cluster"
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version (null = latest)"
  type        = string
  default     = null
}

variable "node_vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_B2s"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}
