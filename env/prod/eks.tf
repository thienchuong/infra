module "eks" {
  source = "../../modules/eks-argocd-cluster"

  cluster_name    = local.cluster_name
  cluster_version = "1.25"

  # network
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa = true

  # cluster add-ons
  cluster_addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    kube-proxy = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
  }

  # node groups
  eks_managed_node_groups = {
    group_1 = {
      bootstrap_extra_args = "--container-runtime containerd --kubelet-extra-args '--max-pods=20'"
      desired_capacity     = 2
      max_capacity         = 1
      min_capacity         = 1
      instance_type        = "t3.medium"
      ami_type             = "AL2_x86_64"
      capacity_type        = "ON_DEMAND"
      labels = {
        "lifecycle" = "OnDemand"
      }
      tags = {
        "Name" = "eks-node-group-1"
      }
      taints = {}
    }
  }
  eks_tags = {
    Environment = "production"
    Terraform   = "true"
  }

  # install argocd #
  enable_argocd         = true
  argocd_manage_add_ons = false # Indicates that ArgoCD is responsible for managing/deploying add-ons
  argocd_helm_config = {
    name             = "argo-cd"
    chart            = "argo-cd"
    repository       = "https://argoproj.github.io/argo-helm"
    version          = "5.29.1"
    namespace        = "argocd"
    timeout          = "1200"
    create_namespace = true
    values           = [templatefile("${path.module}/argocd/values.yaml", {})]
    set_sensitive = [
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = module.argocd-adminpassword.bcrypt_hash
      }
    ]
  }

  argocd_applications = {
    addons = {
      path               = "apps/eks-production/platform"
      repo_url           = "https://github.com/thienchuong/argocd-apps.git"
      add_on_application = false
    }
    workloads = {
      path               = "apps/eks-production/application"
      repo_url           = "https://github.com/thienchuong/argocd-apps.git"
      add_on_application = false
    }
  }

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
}
*/

module "argocd-adminpassword" {
  source = "../../modules/argocd-password"

  length                     = 10
  override_special           = "!#$%&*()-_=+[]{}<>:?"
  secretsmanager_secret_name = "argocd"
}
