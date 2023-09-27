output "hcp_vault_cluster_public_url" {
  value = module.hvn-vault.hcp_vault_cluster_public_url
}

output "hcp_vault_cluster_admin_token" {
  value     = module.hvn-vault.hcp_vault_cluster_admin_token
  sensitive = true
}

output "hcp_vault_cluster_id" {
  value = module.hvn-vault.hcp_vault_cluster_id
}

output "hcp_hvn_id" {
  value = module.hvn-vault.hcp_hvn_id
}

output "hcp_hvn_cluster_cidr" {
  value = module.hvn-vault.hcp_hvn_cluster_cidr
}

output "hcp_hvn_self_link" {
  value       = module.hvn-vault.hcp_hvn_self_link
  description = "A unique URL identifying the HVN."
}

###
output "bastion_host_public_ip" {
  description = "Public IP of the Bastion Host"
  value       = module.documentdb.bastion_host_public_ip
}

output "docdb_cluster_endpoint" {
  description = "Endpoint URL of the DocumentDB Cluster"
  value       = module.documentdb.docdb_cluster_endpoint
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.documentdb.vpc_id
}

output "ssh_command" {
  value = module.documentdb.ssh_command
}
