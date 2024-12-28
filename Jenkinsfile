pipeline {
    agent any
    
    environment {
        TF_PATH = "${WORKSPACE}/terraform"
        TERRAFORM_VERSION = '1.5.7'
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
                    def tfHome = tool name: 'Terraform', type: 'terraform'
                    env.PATH = "${tfHome}:${env.PATH}"
                }
            }
        }

        stage('Terraform Init & Workspace') {
            steps {
                dir(TF_PATH) {
                    script {
                        withCredentials([[
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'aws-credentials',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]]) {
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
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        sh 'terraform validate'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir(TF_PATH) {
                    script {
                        withCredentials([[
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'aws-credentials',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]]) {
                            sh """
                                terraform plan \
                                -var-file="environments/${params.ENVIRONMENT}.tfvars" \
                                -out=tfplan
                            """
                        }
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
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-credentials',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        sh 'terraform apply -auto-approve tfplan'
                    }
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
                        withCredentials([[
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'aws-credentials',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]]) {
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

        stage('Show Outputs') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir(TF_PATH) {
                    script {
                        withCredentials([[
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'aws-credentials',
                            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                        ]]) {
                            def outputs = sh(
                                script: 'terraform output -json',
                                returnStdout: true
                            ).trim()
                            
                            echo "Terraform Outputs: ${outputs}"
                            
                            // Parse JSON outputs if needed
                            def outputsMap = readJSON text: outputs
                            
                            // Access specific output
                            echo "Instance ID: ${outputsMap.instance_id.value}"
                        }
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
            // You can add notification steps here
        }
    }
}
