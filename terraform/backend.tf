terraform {
  backend "s3" {
    bucket         = "company-terraform-states"
    key            = "${terraform.workspace}/infrastructure.tfstate"  # Different prefix per environment
    region         = "us-west-2"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
