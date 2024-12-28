pipeline {
    agent any
    
    environment {
        AWS_CREDENTIALS = credentials('aws-credentials')
        TF_PATH = "${WORKSPACE}/terraform"
        TERRAFORM_VERSION = '1.5.7'  // Specify your Terraform version
    }
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Select environment')
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Terraform') {
            steps {
                script {
                    // Install specific version of Terraform if not already installed
                    def tfHome = tool name: 'Terraform', type: 'terraform'
                    env.PATH = "${tfHome}:${env.PATH}"
                }
            }
        }

        stage('Terraform Init & Workspace') {
            steps {
                dir(TF_PATH) {
                    script {
                        // Initialize with backend config
                        sh """
                            terraform init \
                            -backend-config="bucket=company-terraform-states" \
                            -backend-config="key=${params.ENVIRONMENT}/infrastructure.tfstate" \
                            -backend-config="region=us-west-2" \
                            -backend-config="encrypt=true"
                            
                            terraform workspace select ${params.ENVIRONMENT} || terraform workspace new ${params.ENVIRONMENT}
                        """
                    }
                }
            }
        }

        stage('Terraform Format') {
            steps {
                dir(TF_PATH) {
                    sh 'terraform fmt -check'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir(TF_PATH) {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir(TF_PATH) {
                    script {
                        sh """
                            terraform plan \
                            -var-file="environments/${params.ENVIRONMENT}.tfvars" \
                            -out=tfplan
                        """
                    }
                }
            }
        }

        stage('Apply Approval') {
            when {
                expression { 
                    return params.ACTION == 'apply' && params.ENVIRONMENT == 'prod'
                }
            }
            steps {
                input message: 'Apply production changes?'
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir(TF_PATH) {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                dir(TF_PATH) {
                    script {
                        if (params.ENVIRONMENT == 'prod') {
                            input message: 'Are you sure you want to destroy production infrastructure?'
                        }
                        sh """
                            terraform destroy \
                            -var-file="environments/${params.ENVIRONMENT}.tfvars" \
                            -auto-approve
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline execution failed!'
        }
    }
}
