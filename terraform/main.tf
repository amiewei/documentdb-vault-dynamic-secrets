module "hvn-vault" {
  source     = "./hvn-vault"
  hvn_cidr   = var.hvn_cidr
  aws_region = "us-east-1"

}

module "documentdb" {
  source     = "./documentdb"
  hvn_cidr   = var.hvn_cidr
  aws_region = "us-east-2"
}
