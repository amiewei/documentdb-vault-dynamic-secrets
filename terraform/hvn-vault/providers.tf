terraform {
  cloud {
    organization = "tf-se-test"

    workspaces {
      name = "create-hcp-vault-cluster"
    }
  }

  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.71.1"
    }
  }

  required_version = ">= 1.0"
}

