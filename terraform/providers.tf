terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.41.0"
    }
  }
  required_version = "1.14.8"
  backend "s3" {
    bucket         = "sarfarazkhan11-terraform.tfstate-s3-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "sarfaraj-terraform.tfstate-dynamodb-table"
    use_lockfile = true
    profile        = "sarfaraj"
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}