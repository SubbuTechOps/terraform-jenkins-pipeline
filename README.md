# Terraform Jenkins Pipeline Implementation Guide

## Directory Structure
```
terraform-jenkins-pipeline/
├── .gitignore
├── README.md
├── Jenkinsfile
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── backend.tf
    └── environments/
        ├── dev.tfvars
        ├── staging.tfvars
        └── prod.tfvars
```

## File Contents

### .gitignore
```
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log

# Exclude all .tfvars files, which are likely to contain sensitive data
*.tfvars
!dev.tfvars
!staging.tfvars
!prod.tfvars

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Ignore CLI configuration files
.terraformrc
terraform.rc
```

### Jenkinsfile
```groovy
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
```

### backend.tf
```hcl
terraform {
  backend "s3" {
    # These will be passed via backend-config in terraform init
    # bucket = "company-terraform-states"
    # key    = "<environment>/infrastructure.tfstate"
    # region = "us-west-2"
    # encrypt = true
  }
}
```

### main.tf
```hcl
provider "aws" {
  region = var.aws_region
}

# Example EC2 instance
resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name        = "${var.environment}-instance"
    Environment = var.environment
    Terraform   = "true"
  }
}
```

### variables.tf
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}
```

### environments/dev.tfvars
```hcl
aws_region    = "us-west-2"
environment   = "dev"
instance_type = "t2.micro"
ami_id        = "ami-0c55b159cbfafe1f0"  # Replace with actual AMI ID
```

### environments/staging.tfvars
```hcl
aws_region    = "us-west-2"
environment   = "staging"
instance_type = "t2.medium"
ami_id        = "ami-0c55b159cbfafe1f0"  # Replace with actual AMI ID
```

### environments/prod.tfvars
```hcl
aws_region    = "us-west-2"
environment   = "prod"
instance_type = "t2.large"
ami_id        = "ami-0c55b159cbfafe1f0"  # Replace with actual AMI ID
```

## Jenkins Setup Requirements

1. Install Required Plugins:
   - Pipeline
   - Git
   - AWS Credentials
   - Terraform

2. Configure AWS Credentials:
   - Go to Jenkins > Manage Jenkins > Manage Credentials
   - Add AWS credentials with ID 'aws-credentials'

3. Configure Terraform Tool:
   - Go to Jenkins > Manage Jenkins > Global Tool Configuration
   - Add Terraform installation

## GitHub Repository Setup

1. Create new repository:
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main
```

2. Branch Protection Rules:
   - Require pull request reviews
   - Require status checks to pass
   - Include administrators in restrictions

## Usage Instructions

1. Create a new Jenkins Pipeline job
2. Configure Pipeline:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: Your GitHub repo URL
   - Script Path: Jenkinsfile

3. Run Pipeline:
   - Click "Build with Parameters"
   - Select Environment and Action
   - Click Build

## Best Practices

1. State Management:
   - Use remote state with S3
   - Enable state locking with DynamoDB
   - Enable encryption for state files

2. Security:
   - Use IAM roles with least privilege
   - Enable branch protection rules
   - Require approval for production changes

3. Code Organization:
   - Use consistent formatting
   - Implement proper variable structure
   - Maintain environment separation

4. Pipeline:
   - Include validation steps
   - Implement proper error handling
   - Clean workspace after execution

## Troubleshooting

Common issues and solutions:

1. S3 Backend Issues:
```bash
# Check S3 bucket permissions
aws s3 ls s3://company-terraform-states

# Check DynamoDB table
aws dynamodb describe-table --table-name terraform-lock
```

2. Jenkins Workspace Issues:
```bash
# Clean workspace manually
rm -rf /var/lib/jenkins/workspace/your-pipeline-name/*
```

3. Terraform State Issues:
```bash
# Force unlock state
terraform force-unlock <lock-id>
```

Remember to replace placeholder values (AMI IDs, region, bucket names) with your actual values before implementation.
