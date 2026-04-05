
# Get available AZs
data "aws_availability_zones" "available" {}

# -----------------------------
# VPC for EKS
# -----------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "eks-clean-vpc"
  cidr = "10.0.0.0/16"

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  public_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Environment = "lab"
    Project     = "eks-lab"
  }
}

# -----------------------------
# EKS Cluster
# -----------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "eks-lab"
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = false
  cluster_endpoint_public_access_cidrs = ["73.142.11.59/32"]

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
    
      instance_types = ["t3.xlarge"]
      capacity_type  = "ON_DEMAND"
      # Safeguard: max_size is always at least 1
      min_size     = var.node_min_size
      desired_size = var.node_desired_size
      max_size     = var.node_max_size

      labels = {
        role = "worker"
      }

      tags = {
        Name = "eks-clean-node"
      }
    }
  }

  tags = {
    Environment = "lab"
    Project     = "eks-lab"
  }
}