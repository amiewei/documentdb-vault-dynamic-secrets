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
      version = "~> 4.0"
    }
  }

  required_version = ">= 0.14.0"
}
