module "load_balancer_controller_irsa_role" {
  source = "../../modules/iam-role-for-service-accounts-eks"

  role_name                              = "load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["aws-load-balancer-controller:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}
