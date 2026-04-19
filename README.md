# DevOps Lab on AWS

A cost-effective DevOps lab (~$8-10/month) built on AWS using Terraform, Jenkins, EKS, ArgoCD, Prometheus, Grafana, and Loki.

## Architecture

```
GitHub → Jenkins (CI) → ECR (Docker images)
                     → EKS (Kubernetes)
                          → ArgoCD (GitOps)
                          → Prometheus + Grafana (metrics)
                          → Loki + Promtail (logs)
```

## Stack

| Tool | Purpose |
|---|---|
| Terraform | Infrastructure as Code |
| Jenkins | CI server, EKS lifecycle management |
| EKS | Kubernetes cluster (Spot nodes) |
| ArgoCD | GitOps CD — syncs manifests from GitHub |
| Prometheus + Grafana | Metrics and dashboards |
| Loki + Promtail | Log aggregation |
| ECR | Docker image registry |
| S3 + DynamoDB | Terraform remote state backend |

## Cost Strategy

- **Always on:** Jenkins EC2 Spot t3.medium (~$7/month)
- **On-demand:** EKS cluster destroyed nightly, recreated when needed (~$0.20/hr)
- **Target:** ~$8-10/month

## Project Structure

```
.
├── backend/                        # Terraform: S3 + DynamoDB remote state
├── jenkins/                        # Terraform: Jenkins EC2 Spot + IAM
├── eks/                            # Terraform: EKS cluster + Spot nodes
├── ecr/                            # Terraform: ECR repositories
├── jenkins-pipelines/
│   └── eks-bootstrap.Jenkinsfile   # Full EKS lifecycle pipeline
└── k8s/
    ├── argocd/
    │   └── app-of-apps.yaml        # ArgoCD root application
    └── apps/
        ├── prometheus-grafana.yaml  # kube-prometheus-stack
        ├── loki.yaml                # Loki + Promtail
        └── loki-datasource.yaml    # Grafana datasource for Loki
```

## Setup

### Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.5.0
- kubectl

### 1. Deploy Backend (once only)

```bash
cd backend
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

### 2. Deploy Jenkins (once only)

```bash
cd jenkins
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

Get Jenkins initial password via SSM:
```bash
aws ssm start-session --target <instance_id> --region us-east-1
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 3. Set Up Jenkins Pipeline

1. New Item → `eks-bootstrap` → Pipeline
2. Pipeline script from SCM → Git
3. Repo URL: `https://github.com/mjiruvuri/iruvuri_devops.git`
4. Script Path: `jenkins-pipelines/eks-bootstrap.Jenkinsfile`

### 4. Start EKS + Full Stack

In Jenkins → `eks-bootstrap` → **Build with Parameters** → `apply`

This will:
- Create EKS cluster with Spot nodes
- Install ArgoCD
- Deploy Prometheus + Grafana + Loki via ArgoCD
- Grant kubectl access to your IAM user
- Print all URLs and credentials

### 5. Stop EKS (to save cost)

In Jenkins → `eks-bootstrap` → **Build with Parameters** → `destroy`

## Daily Workflow

```
Start  → Jenkins → eks-bootstrap → apply   (~15 min)
Stop   → Jenkins → eks-bootstrap → destroy (~5 min)
```

## Security

- No AWS credentials in code — Jenkins uses IAM Instance Profile
- No secrets committed — `terraform.tfvars` is gitignored
- All sensitive values in variables, examples in `*.tfvars.example`
- Public repo safe — validated with secret scanning

## Terraform Variables

Copy `terraform.tfvars.example` to `terraform.tfvars` in each module and fill in your values. The example files show the required format.

| Module | Key Variables |
|---|---|
| `backend/` | `aws_region`, `state_bucket_name` |
| `jenkins/` | `aws_region`, `ami_id`, `allowed_cidr`, `state_bucket_name` |
| `eks/` | `aws_region`, `cluster_name`, `kubernetes_version` |
| `ecr/` | `aws_region`, `repositories` |
