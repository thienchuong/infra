module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>5.0.0"

  name = var.vpc_name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway     = var.enable_nat_gateway
  enable_vpn_gateway     = var.enable_vpn_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  single_nat_gateway     = var.single_nat_gateway

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support


  public_subnet_tags = var.public_subnet_tags
  private_subnet_tags = var.private_subnet_tags

  tags = var.vpc_tags
}
