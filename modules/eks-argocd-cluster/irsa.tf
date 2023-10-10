locals {
  k8s-loki-sva                         = "loki"
  loki-ns                              = "logging"
  k8s-aws-load-balancer-controller-sva = "aws-load-balancer-controller"
  aws-load-balancer-controller-ns      = "aws-load-balancer-controller"
  k8s-karpenter-sva                    = "karpenter"
  karpenter-ns                         = "karpenter"


}
module "load_balancer_controller_irsa_role" {
  count   = var.load-balancer-controller-enabled ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name                              = "load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.aws-load-balancer-controller-ns}:${local.k8s-aws-load-balancer-controller-sva}"]
    }
  }
}

module "karpenter_irsa_role" {
  count = var.karpenter-enabled ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name                          = "karpenter"
  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_name       = module.eks.cluster_name
  karpenter_controller_node_iam_role_arns = [module.eks.eks_managed_node_groups["group_1"].iam_role_arn]

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.karpenter-ns}:${local.k8s-karpenter-sva}"]
    }
  }
}
