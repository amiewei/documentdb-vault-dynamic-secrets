# Creates a HVN for Vault
resource "hcp_hvn" "hcp-vault-hvn-example" {
  hvn_id         = "hcp-vault-hvn-example"
  cloud_provider = "aws"
  region         = var.aws_region
  cidr_block     = var.hvn_cidr
}

# Creates a HCP Vault Cluster
resource "hcp_vault_cluster" "hcp-vault-cluster-example" {
  cluster_id      = "hcp-vault-cluster-example"
  hvn_id          = hcp_hvn.hcp-vault-hvn-example.hvn_id
  tier            = "dev"
  public_endpoint = true
}

# Creates an Admin token for the HCP Vault Cluster 
resource "hcp_vault_cluster_admin_token" "tfc-vault-token" {
  cluster_id = hcp_vault_cluster.hcp-vault-cluster-example.cluster_id
}

# # Create variable set for reused variables
# resource "tfe_variable_set" "vault-dpc-demo" {
#   name        = "Vault DPC Demo"
#   description = "Common variables for the Vault DPC Demo workspaces"
# }

# # Configure variables in Vault DPC demo variable set
# resource "tfe_variable" "region" {
#   key             = "region"
#   value           = var.region
#   category        = "terraform"
#   variable_set_id = tfe_variable_set.vault-dpc-demo.id
# }

# resource "tfe_variable" "vault_addr" {
#   key             = "vault_addr"
#   value           = hcp_vault_cluster.hcp-vault-cluster-example.vault_public_endpoint_url
#   category        = "terraform"
#   variable_set_id = tfe_variable_set.vault-dpc-demo.id
# }

# resource "tfe_variable" "tfc_hostname" {
#   key             = "tfc_hostname"
#   value           = var.tfc_hostname
#   category        = "terraform"
#   variable_set_id = tfe_variable_set.vault-dpc-demo.id
# }

# resource "tfe_variable" "tfc_token" {
#   key             = "tfc_token"
#   value           = var.tfc_token
#   category        = "terraform"
#   variable_set_id = tfe_variable_set.vault-dpc-demo.id
#   sensitive       = true
# }

# resource "tfe_variable" "tfc_organization_name" {
#   key             = "tfc_organization_name"
#   value           = var.tfc_organization_name
#   category        = "terraform"
#   variable_set_id = tfe_variable_set.vault-dpc-demo.id
# }

# resource "tfe_variable" "tfc_project_name" {
#   key             = "tfc_project_name"
#   value           = var.tfc_project_name
#   category        = "terraform"
#   variable_set_id = tfe_variable_set.vault-dpc-demo.id
# }

# resource "tfe_variable" "hvn_id" {
#   key             = "hvn_id"
#   value           = hcp_hvn.vault-dpc-demo-hvn.hvn_id
#   category        = "terraform"
#   variable_set_id = tfe_variable_set.vault-dpc-demo.id
# }

# resource "tfe_variable" "hvn_cidr" {
#   key             = "hvn_cidr"
#   value           = hcp_hvn.vault-dpc-demo-hvn.cidr_block
#   category        = "terraform"
#   variable_set_id = tfe_variable_set.vault-dpc-demo.id
# }

# resource "tfe_variable" "hvn_self_link" {
#   key             = "hvn_self_link"
#   value           = hcp_hvn.vault-dpc-demo-hvn.self_link
#   category        = "terraform"
#   variable_set_id = tfe_variable_set.vault-dpc-demo.id
# }

# resource "tfe_variable" "hcp_client_id" {
#   key             = "hcp_client_id"
#   value           = var.hcp_client_id
#   category        = "terraform"
#   variable_set_id = tfe_variable_set.vault-dpc-demo.id
# }

# resource "tfe_variable" "hcp_client_secret" {
#   key             = "hcp_client_secret"
#   value           = var.hcp_client_secret
#   category        = "terraform"
#   variable_set_id = tfe_variable_set.vault-dpc-demo.id
#   sensitive       = true
# }

# # Add variable set to project
# resource "tfe_project_variable_set" "vault-dpc-demo" {
#   variable_set_id = tfe_variable_set.vault-dpc-demo.id
#   project_id      = data.tfe_project.vault-dpc-demo.id
# }

# # Create workspace to configure Vault KV store, JWT auth and AWS secrets engine
# resource "tfe_workspace" "vault-dpc-demo-build" {
#   name           = "vault-dpc-demo-build"
#   organization   = var.tfc_organization_name
#   project_id     = data.tfe_project.vault-dpc-demo.id
#   execution_mode = "remote"
# }

# # Configure variables in vault-dpc-demo-build workspace
# resource "tfe_variable" "vault_token" {
#   key          = "VAULT_TOKEN"
#   value        = hcp_vault_cluster_admin_token.tfc-vault-token.token
#   category     = "env"
#   workspace_id = tfe_workspace.vault-dpc-demo-build.id
#   sensitive    = true
# }

# resource "tfe_variable" "aws_client_id" {
#   key          = "AWS_ACCESS_KEY_ID"
#   value        = var.aws_client_id
#   category     = "env"
#   workspace_id = tfe_workspace.vault-dpc-demo-build.id
# }

# resource "tfe_variable" "aws_secret_key" {
#   key          = "AWS_SECRET_ACCESS_KEY"
#   value        = var.aws_secret_key
#   category     = "env"
#   workspace_id = tfe_workspace.vault-dpc-demo-build.id
#   sensitive    = true
# }
