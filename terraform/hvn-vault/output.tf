output "hcp_vault_cluster_public_url" {
  value = hcp_vault_cluster.hcp-vault-cluster-example.vault_public_endpoint_url
}

output "hcp_vault_cluster_admin_token" {
  value     = hcp_vault_cluster_admin_token.tfc-vault-token.token
  sensitive = true
}

output "hcp_vault_cluster_id" {
  value = hcp_vault_cluster.hcp-vault-cluster-example.cluster_id
}

output "hcp_hvn_id" {
  value = hcp_hvn.hcp-vault-hvn-example.hvn_id
}

output "hcp_hvn_cluster_cidr" {
  value = hcp_hvn.hcp-vault-hvn-example.cidr_block
}

output "hcp_hvn_self_link" {
  value       = hcp_hvn.hcp-vault-hvn-example.self_link
  description = "A unique URL identifying the HVN."
}
