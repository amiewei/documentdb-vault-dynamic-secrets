variable "hvn_cidr" {
  type        = string
  description = "CIDR block of the HVN to create for the Vault cluster"
  default     = "172.25.16.0/20"
}
