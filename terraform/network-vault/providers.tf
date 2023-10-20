terraform {
  cloud {
    organization = "tf-se-test"

    workspaces {
      name = "aws-network-hcp-vault"
    }
  }

  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.71.1"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }

  }

  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

provider "hcp" {

}
