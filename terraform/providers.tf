terraform {
  cloud {
    organization = "tf-se-test"

    workspaces {
      name = "vault-documentdb-dynamic-secrets"
    }
  }

  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.71.1"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

  }

  required_version = ">= 1.0"
}

