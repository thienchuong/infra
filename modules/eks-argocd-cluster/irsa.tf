data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
locals {
  k8s-loki-sva                         = "loki"
  loki-ns                              = "logging"
  k8s-aws-load-balancer-controller-sva = "aws-load-balancer-controller"
  aws-load-balancer-controller-ns      = "aws-load-balancer-controller"
  k8s-karpenter-sva                    = "karpenter"
  karpenter-ns                         = "karpenter"
  external-secrets-ns                  = "external-secrets"
  k8s-external-secrets-sva             = "external-secrets"
  aws-ebs-csi-driver-ns                = "aws-ebs-csi-driver"
  k8s-aws-ebs-csi-driver-sva           = "aws-ebs-csi-driver"
  account_id                           = data.aws_caller_identity.current.account_id
  partition                            = data.aws_partition.current.partition
  dns_suffix                           = data.aws_partition.current.dns_suffix
  region                               = data.aws_region.current.name
  karpenter_controller_cluster_name    = module.eks.cluster_name
}


################################################################################
# Aws load balancer controller policy
################################################################################

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


################################################################################
# Karpenter Controller Policy
################################################################################

module "karpenter_irsa_role" {
  count = var.karpenter-enabled ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name                          = "karpenter"
  attach_karpenter_controller_policy = false

  role_policy_arns = {
    policy = aws_iam_policy.karpenter[0].arn
  }

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

data "aws_iam_policy_document" "karpenter" {

  statement {
    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "pricing:GetProducts",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
    ]

    resources = ["*"]

  }

  statement {
    actions = ["ec2:RunInstances"]
    resources = [
      "arn:${local.partition}:ec2:*:${local.account_id}:launch-template/*",
    ]

  }

  statement {
    actions = ["ec2:RunInstances"]
    resources = [
      "arn:${local.partition}:ec2:*::image/*",
      "arn:${local.partition}:ec2:*:${local.account_id}:instance/*",
      "arn:${local.partition}:ec2:*:${local.account_id}:spot-instances-request/*",
      "arn:${local.partition}:ec2:*:${local.account_id}:security-group/*",
      "arn:${local.partition}:ec2:*:${local.account_id}:volume/*",
      "arn:${local.partition}:ec2:*:${local.account_id}:network-interface/*",
      "arn:${local.partition}:ec2:*:${coalesce(var.karpenter_subnet_account_id, local.account_id)}:subnet/*",
    ]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = var.karpenter_controller_ssm_parameter_arns
  }

  statement {
    actions   = ["iam:PassRole"]
    resources = var.karpenter_controller_node_iam_role_arns
  }

  statement {
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:${local.partition}:eks:${local.region}:${local.account_id}:cluster/${local.karpenter_controller_cluster_name}"]
  }

  dynamic "statement" {
    for_each = var.karpenter_sqs_queue_arn != null ? [1] : []

    content {
      actions = [
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage",
      ]
      resources = [var.karpenter_sqs_queue_arn]
    }
  }
}

resource "aws_iam_policy" "karpenter" {
  count       = var.karpenter-enabled ? 1 : 0
  name_prefix = "${var.policy_name_prefix}Karpenter_Controller_Policy-"
  description = "Provides permissions for Karpenter to manage EC2 instances"
  policy      = data.aws_iam_policy_document.karpenter.json
}


################################################################################
# External secret policy
################################################################################

module "external_secrets_irsa_role" {
  count   = var.external-secrets-enabled ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name                      = "external-secrets"
  attach_external_secrets_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.external-secrets-ns}:${local.k8s-external-secrets-sva}"]
    }
  }
}

################################################################################
# aws-ebs-csi-driver policy
################################################################################
module "aws-ebs-csi-driver_irsa_role" {
  count   = var.aws-ebs-csi-driver-enabled ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name                        = "aws-ebs-csi-driver"
  attach_ebs_csi_policy            = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.aws-ebs-csi-driver-ns}:${local.k8s-aws-ebs-csi-driver-sva}"]
    }
  }
}
