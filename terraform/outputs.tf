# outputs.tf

# Instance Details
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.example.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.example.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.example.private_ip
}

# Environment Information
output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "workspace_info" {
  description = "Current Terraform workspace"
  value       = terraform.workspace
}

# Tag Information
output "instance_tags" {
  description = "Tags associated with the instance"
  value       = aws_instance.example.tags
}

# Deployment Information
output "deployment_info" {
  description = "Information about the deployment"
  value = {
    region          = var.aws_region
    instance_type   = var.instance_type
    environment     = var.environment
    terraform_workspace = terraform.workspace
  }
}
