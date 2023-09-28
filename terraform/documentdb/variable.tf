

variable "aws_region" {
  description = "AWS Region to deploy to"
  type        = string
  default     = "us-east-1" # need to match the AWS VPC for DocumentDB created in networking
}

variable "project_name" {
  description = "project name is used as resource tag"
  type        = string
  default     = "documentdb_vault_test"
}

variable "private_subnets" {
  description = "Private subnets for DocumentDB"
  default = [
    {
      cidr_block        = "10.0.200.0/24"
      availability_zone = "a"
      name              = "private-subnet-1"
    },
    {
      cidr_block        = "10.0.201.0/24"
      availability_zone = "b"
      name              = "private-subnet-2"
    }
  ]
}

variable "hvn_cidr" {
  type        = string
  description = "CIDR block of the HVN to create for the Vault cluster"
  default     = "172.25.16.0/20"
}
