terraform {
    required_version = ">= 0.12.0"
    required_providers {
        aws = ">= 2.0.0"
    }
    backend "s3" {
        bucket = "terraform-state-{{ cookiecutter.project_name }}"
        key    = "terraform.tfstate"
        region = "ap-northeast-2"
    }
}