variable "hvn_cidr" {
  type        = string
  description = "CIDR block of the HVN to create for the Vault cluster"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to deploy infrastructure into"
  default     = "us-east-2"
}

# variable "tfc_hostname" {
#   type        = string
#   description = "The TFE/TFC hostname"
# }

# variable "tfc_organization_name" {
#   type        = string
#   description = "The TFC Organization Name"
# }

# variable "tfc_project_name" {
#   type        = string
#   description = "The TFC Project to deploy into"
# }

# variable "tfc_token" {
#   type        = string
#   description = "The token to use to configure the TFE provider"
# }

# variable "hcp_client_id" {
#   type        = string
#   description = "The client ID to use in the HCP provider"
# }

# variable "hcp_client_secret" {
#   type        = string
#   description = "The client secret to use in the HCP provider"
# }

# variable "aws_client_id" {
#   type        = string
#   description = "The client ID to use to provision initial AWS infrastructure"
# }

# variable "aws_secret_key" {
#   type        = string
#   description = "The secret key to use to provision initial AWS infrastructure"
# }
