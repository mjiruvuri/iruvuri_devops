pipeline {
    agent any

    environment {
        AWS_REGION      = 'us-east-1'
        TF_DIR          = 'eks'
        CLUSTER_NAME    = 'eks-lab'
    }

    triggers {
        // Destroy at 20:00 UTC, apply at 12:00 UTC Mon-Fri
        cron('0 20 * * 1-5\n0 12 * * 1-5')
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Apply or destroy the EKS cluster'
        )
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
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
            post {
                success {
                    sh """
                        aws eks update-kubeconfig \
                          --region ${AWS_REGION} \
                          --name ${CLUSTER_NAME}
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
    }

    post {
        failure {
            echo "Pipeline failed — check the logs above."
        }
    }
}
