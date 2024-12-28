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
