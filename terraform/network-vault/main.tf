
######################### HVN for Vault & HCP Vault Cluster ##############################

# Create a HVN in AWS for Vault
resource "hcp_hvn" "hcp_vault_hvn_example" {
  hvn_id         = "hcp-vault-hvn-example"
  cloud_provider = "aws"
  region         = var.aws_region
  cidr_block     = var.hvn_cidr
}


# Create a HCP Vault Cluster
resource "hcp_vault_cluster" "hcp_vault_cluster_example" {
  cluster_id      = "hcp-vault-cluster-example"
  hvn_id          = hcp_hvn.hcp_vault_hvn_example.hvn_id
  tier            = "dev"
  public_endpoint = true
}

# Create an Admin token for the HCP Vault Cluster 
resource "hcp_vault_cluster_admin_token" "tfc_vault_token" {
  cluster_id = hcp_vault_cluster.hcp_vault_cluster_example.cluster_id
}

############################### AWS VPC For DocumentDB ################################# 

# VPC for Vault
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.aws_cidr
  enable_dns_support   = true # Enable DNS support
  enable_dns_hostnames = true # Enable DNS hostnames
  tags = {
    Name = "my-vpc"
  }
}

# Find the main route table for the VPC
data "aws_route_table" "main" {
  vpc_id = aws_vpc.my_vpc.id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# Add a route to the main route table to allow traffic for VPC Peering (as configured in section below)
resource "aws_route" "example" {
  route_table_id            = data.aws_route_table.main.id
  destination_cidr_block    = var.hvn_cidr
  vpc_peering_connection_id = hcp_aws_network_peering.hcp_aws_network_peer.provider_peering_id
}

#################################### VPC Peering ###################################### 

#  Create an HCP network peering to peer your HVN with your AWS VPC. 
#  This resource initially returns in a Pending state, 
#  because its provider_peering_id is required to complete acceptance of the connection.
resource "hcp_aws_network_peering" "hcp_aws_network_peer" {
  peering_id      = var.peer_id
  hvn_id          = hcp_hvn.hcp_vault_hvn_example.hvn_id
  peer_vpc_id     = aws_vpc.my_vpc.id
  peer_account_id = aws_vpc.my_vpc.owner_id
  peer_vpc_region = var.aws_region
}

# This data source is the same as the resource above, but waits for the connection to be Active before returning.
data "hcp_aws_network_peering" "hcp_aws_network_peer" {
  hvn_id                = hcp_hvn.hcp_vault_hvn_example.hvn_id
  peering_id            = hcp_aws_network_peering.hcp_aws_network_peer.peering_id
  wait_for_active_state = true
}

# Accept the VPC peering within your AWS account.
resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.hcp_aws_network_peer.provider_peering_id
  auto_accept               = true
}

# Create an HVN route that targets your HCP network peering and matches your AWS VPC's CIDR block.
# The route depends on the data source, rather than the resource, to ensure the peering is in an Active state.
resource "hcp_hvn_route" "hvn_route" {
  hvn_link         = hcp_hvn.hcp_vault_hvn_example.self_link
  hvn_route_id     = var.route_id
  destination_cidr = aws_vpc.my_vpc.cidr_block
  target_link      = data.hcp_aws_network_peering.hcp_aws_network_peer.self_link
}
