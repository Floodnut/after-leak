provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.aws_region
}

terraform {
    required_version = ">= 0.12.0"
    required_providers {
        aws = ">= 2.0.0"
    }
    backend "s3" {
        bucket = "tf-state"
        key    = "terraform.tfstate"
        region = "ap-northeast-2"
    }
}
