output "hcp_vault_cluster_public_url" {
  value = hcp_vault_cluster.hcp_vault_cluster_example.vault_public_endpoint_url
}

output "hcp_vault_cluster_admin_token" {
  value     = hcp_vault_cluster_admin_token.tfc_vault_token.token
  sensitive = true
}

output "hcp_vault_cluster_id" {
  value = hcp_vault_cluster.hcp_vault_cluster_example.cluster_id
}

output "hcp_hvn_id" {
  value = hcp_hvn.hcp_vault_hvn_example.hvn_id
}

output "hcp_hvn_cluster_cidr" {
  value = hcp_hvn.hcp_vault_hvn_example.cidr_block
}

output "hcp_hvn_self_link" {
  value       = hcp_hvn.hcp_vault_hvn_example.self_link
  description = "A unique URL identifying the HVN"
}

output "aws_vpc_my_vpc_id" {
  value = aws_vpc.my_vpc.id
}
