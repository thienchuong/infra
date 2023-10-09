module "vpc" {
  source = "../../modules/network"

  vpc_name = "eks-vpc-production"
  cidr     = "10.0.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  enable_vpn_gateway     = false
  one_nat_gateway_per_az = true
  single_nat_gateway     = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    Name                                          = "public-subnets"
    "kubernetes.io/role/elb"                      = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
  private_subnet_tags = {
    Name                                          = "private-subnets"
    "kubernetes.io/role/internal-elb"             = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
  vpc_tags = {
    Terraform   = "true"
    Environment = "production"
  }
}
