module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name  = "thienchuong.xyz"
  zone_id      = "Z0309504BS4N0050VHBU"

  validation_method = "DNS"

  subject_alternative_names = [
    "*.thienchuong.xyz",
  ]

  wait_for_validation = true

  tags = {
    Name = "thienchuong.xyz"
    Terraform   = "true"
  }
}
