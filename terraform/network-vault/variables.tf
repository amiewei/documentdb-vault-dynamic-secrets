variable "aws_region" {
  type        = string
  description = "The AWS region to deploy DocumentDB and EC2 infrastructure into"
  default     = "us-east-1"
}

# variable "aws_region_hvn" {
#   type        = string
#   description = "The AWS region for HVN"
#   default     = "us-east-2"
# }

variable "aws_cidr" {
  type        = string
  description = "CIDR block of the AWS VPC for DocumentDB resources"
  default     = "10.0.0.0/16"
}

variable "hvn_cidr" {
  type        = string
  description = "CIDR block of the HVN to create for the Vault cluster"
  default     = "172.25.16.0/20"
}


variable "route_id" {
  type        = string
  description = "HVN Route ID"
  default     = "hvn-hcp-vault-route"
}

variable "peer_id" {
  type        = string
  description = "HCP AWS Network Peering ID"
  default     = "hvn-aws-peering"
}
