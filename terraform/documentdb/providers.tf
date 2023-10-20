terraform {

  cloud {
    organization = "tf-se-test" # replace with your org

    workspaces {
      name = "aws-documentdb"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }

  required_version = ">= 0.14.0"
}

provider "aws" {
  region = var.aws_region
}
