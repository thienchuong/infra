locals {
  cluster_name = "eks-production"
  tags = {
    Terraform   = "true"
    Environment = "production"
  }
}
