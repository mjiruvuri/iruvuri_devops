pipeline {
    agent any

    environment {
        AWS_REGION   = 'us-east-1'
        CLUSTER_NAME = 'eks-lab'
        TF_DIR       = 'eks'
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Apply (create + bootstrap) or Destroy the EKS cluster'
        )
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Ensure Tools') {
            steps {
                sh '''
                    # Copy tools from host if missing in container
                    which terraform || cp /usr/local/bin/terraform /usr/local/bin/terraform 2>/dev/null || true
                    which kubectl   || cp /usr/local/bin/kubectl   /usr/local/bin/kubectl   2>/dev/null || true
                    which aws       || true
                    terraform version
                    kubectl version --client
                    aws --version
                '''
            }
        }

        stage('Terraform Init') {
            steps {
                dir(TF_DIR) {
                    sh 'terraform init -reconfigure'
                }
            }
        }

        stage('Terraform Apply') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                dir(TF_DIR) {
                    sh """
                        terraform apply -auto-approve \
                          -var="aws_region=${AWS_REGION}" \
                          -var="cluster_name=${CLUSTER_NAME}"
                    """
                }
            }
        }

        stage('Terraform Destroy') {
            when { expression { params.ACTION == 'destroy' } }
            steps {
                dir(TF_DIR) {
                    sh """
                        terraform destroy -auto-approve \
                          -var="aws_region=${AWS_REGION}" \
                          -var="cluster_name=${CLUSTER_NAME}"
                    """
                }
            }
        }

        stage('Configure kubectl') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh """
                    aws eks update-kubeconfig \
                      --region ${AWS_REGION} \
                      --name ${CLUSTER_NAME}
                """
            }
        }

        stage('Wait for Nodes') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh '''
                    echo "Waiting for EKS API server to accept connections..."
                    for i in $(seq 1 30); do
                        if kubectl cluster-info > /dev/null 2>&1; then
                            echo "API server is reachable"
                            break
                        fi
                        echo "Attempt $i/30 — not ready yet, retrying in 15s..."
                        sleep 15
                    done

                    echo "Waiting for EKS nodes to be Ready..."
                    kubectl wait --for=condition=Ready nodes \
                      --all --timeout=300s
                    kubectl get nodes
                '''
            }
        }

        stage('Install ArgoCD') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh '''
                    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
                    kubectl apply -n argocd \
                      -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
                    kubectl patch svc argocd-server -n argocd \
                      -p '{"spec": {"type": "LoadBalancer"}}'

                    echo "Waiting for ArgoCD server to be ready..."
                    kubectl wait --for=condition=available deployment/argocd-server \
                      -n argocd --timeout=300s
                '''
            }
        }

        stage('Apply ArgoCD Apps') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh '''
                    kubectl apply -f k8s/argocd/app-of-apps.yaml
                    kubectl apply -f k8s/apps/prometheus-grafana.yaml
                    kubectl apply -f k8s/apps/loki.yaml
                    kubectl apply -f k8s/apps/loki-datasource.yaml
                '''
            }
        }

        stage('Grant Local Access') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh """
                    ACCOUNT_ID=\$(aws sts get-caller-identity --query Account --output text)
                    USER_ARN="arn:aws:iam::\${ACCOUNT_ID}:user/iruvuri-tf-user"

                    aws eks update-cluster-config \
                      --name ${CLUSTER_NAME} \
                      --region ${AWS_REGION} \
                      --access-config authenticationMode=API_AND_CONFIG_MAP 2>/dev/null || true

                    sleep 20

                    aws eks create-access-entry \
                      --cluster-name ${CLUSTER_NAME} \
                      --principal-arn \$USER_ARN \
                      --region ${AWS_REGION} 2>/dev/null || true

                    aws eks associate-access-policy \
                      --cluster-name ${CLUSTER_NAME} \
                      --principal-arn \$USER_ARN \
                      --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
                      --access-scope type=cluster \
                      --region ${AWS_REGION} 2>/dev/null || true

                    echo "Access granted to \$USER_ARN"
                """
            }
        }

        stage('Print Endpoints') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                sh '''
                    echo "======================================"
                    echo "Cluster is ready!"
                    echo "======================================"
                    echo ""
                    echo "ArgoCD URL:"
                    kubectl get svc argocd-server -n argocd \
                      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
                    echo ""
                    echo ""
                    echo "ArgoCD Password:"
                    kubectl get secret argocd-initial-admin-secret \
                      -n argocd \
                      -o jsonpath='{.data.password}' | base64 -d
                    echo ""
                    echo ""
                    echo "Grafana URL (wait 3-5 min for LB):"
                    kubectl get svc prometheus-grafana -n monitoring \
                      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not ready yet - check in a few minutes"
                    echo ""
                    echo "Grafana login: admin / admin"
                    echo "======================================"
                '''
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed — check logs above."
        }
    }
}
