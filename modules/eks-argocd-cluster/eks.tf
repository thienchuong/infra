module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.12"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # network
  vpc_id                          = var.vpc_id
  subnet_ids                      = var.subnet_ids
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  enable_irsa = var.enable_irsa

  # cluster add-ons
  cluster_addons = var.cluster_addons

  # node groups
  eks_managed_node_groups = var.eks_managed_node_groups
  tags = var.eks_tags

}

module "eks_argocd_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.32.1"

  eks_cluster_id        = module.eks.cluster_name
  eks_cluster_endpoint  = module.eks.cluster_endpoint
  eks_cluster_version   = module.eks.cluster_version
  eks_oidc_provider     = module.eks.oidc_provider
  eks_oidc_provider_arn = module.eks.oidc_provider_arn

  enable_argocd         = var.enable_argocd
  argocd_manage_add_ons = var.argocd_manage_add_ons # Indicates that ArgoCD is responsible for managing/deploying add-ons
  argocd_helm_config = var.argocd_helm_config


  argocd_applications = var.argocd_applications
  tags = var.eks_tags
}


/* # template for creating argocd project/applicationsets/applications
resource "helm_release" "argocd_application" {
  count = var.enable_argocd ? 1 : 0

  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "1.4.1"
  namespace  = "argocd"

  values = [templatefile("${path.module}/helm-chart/argocd_applicationset.tftpl", {
    argocd_applications = var.argocd_applicationset_helm_values
  })]
} */
