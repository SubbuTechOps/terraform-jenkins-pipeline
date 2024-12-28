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
