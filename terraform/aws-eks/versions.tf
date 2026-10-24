terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Remote state: uncomment and fill in once you have an S3 bucket + DynamoDB lock table.
  # backend "s3" {
  #   bucket         = "<your-tfstate-bucket>"
  #   key            = "devops-demo/aws-eks/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "<your-lock-table>"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}
