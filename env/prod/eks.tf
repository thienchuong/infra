locals {
  cluster_name = "eks-production"
  tags = {
    Terraform   = "true"
    Environment = "production"
  }
}

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

  # eks_managed_node_groups
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
# Allows Control Plane Nodes to talk to Worker nodes on port 8443 karpenter 8443
  cluster_security_group_additional_rules = {
    ingress_nodes_karpenter_ports_tcp = {
      description                = "Karpenter readiness"
      protocol                   = "tcp"
      from_port                  = 8443
      to_port                    = 8443
      type                       = "ingress"
      source_node_security_group = true
    }
  }
}
  tags = local.tags

  # setups irsa for platform services
  load-balancer-controller-enabled = true
  karpenter-enabled                = true

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

module "argocd-adminpassword" {
  source = "../../modules/argocd-password"

  length                     = 10
  override_special           = "!#$%&*()-_=+[]{}<>:?"
  secretsmanager_secret_name = "argocd"
}
