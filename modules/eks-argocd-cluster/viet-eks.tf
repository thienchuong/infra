/* # Locals Block
locals {
  # # Used to determine correct partition (i.e. - `aws`, `aws-gov`, `aws-cn`, etc.)
  # partition = data.aws_partition.current.partition
  node_tags = {
    # "karpenter.sh/discovery/${var.cluster_name}" = "${var.cluster_name}"
    "Name" = "spot"
  }
}

#############################################
#                   EKS                     #
#############################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  # EKS CLUSTER
  cluster_name    = var.cluster_name
  cluster_version = var.eks_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa = true

  # https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/README.md
  manage_aws_auth_configmap = true
  aws_auth_users = flatten([
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.admin_iam_user}" # The ARN of the IAM role
      username = "vietwow"                                                                                # The user name within Kubernetes to map to the IAM role
      groups   = ["system:masters"]                                                                       # A list of groups within Kubernetes to which the role is mapped; Checkout K8s Role and Rolebindings
    },
    {
      userarn  = var.iam_user_arn
      username = var.iam_user_name
      groups   = ["eks-ro-user-cluster-role"]
    }
  ])

  aws_auth_roles = flatten([
    #   #module.eks_blueprints_platform_teams.aws_auth_configmap_role,
    #   #[for team in module.eks_blueprints_dev_teams : team.aws_auth_configmap_role],
    # We need to add in the Karpenter node IAM role for nodes launched by Karpenter
    {
      rolearn  = module.eks_kubernetes_addons.karpenter.node_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  ])

  ## EKS MANAGED NODE GROUPS

  # fargate_profiles = {
  #   karpenter = {
  #     selectors = [
  #       { namespace = "karpenter" }
  #     ]
  #   }
  #   kube_system = {
  #     name = "kube-system"
  #     selectors = [
  #       { namespace = "kube-system" }
  #     ]
  #   }
  # }

  eks_managed_node_groups = {
    spot = {
      node_group_name = "AMAZE-SPOT"
      instance_types  = ["m5.large", "m5a.large", "m5d.large", "m5ad.large"]

      # ami_id = data.aws_ami.eks_golden_image.image_id

      min_size      = 1
      desired_size  = 1
      max_size      = 3
      capacity_type = "SPOT"

      # IAM Policies for Cluster-AutoScaler (not Karpenter)
      create_iam_role = true
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
        CloudWatchAgentServerPolicy  = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
        AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        # EC2InstanceProfileForImageBuilderECRContainerBuilds = "arn:${data.aws_partition.current.partition}:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
        # additional                   = aws_iam_policy.push_to_ecr.arn
      }

      create_launch_template = true # false will use the default launch template

      ec2_ssh_key           = ""
      ssh_security_group_id = ""
      enable_monitoring     = true

      ebs_optimized = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 100
            volume_type = "gp3"
            iops        = 3000
            throughput  = 150
            encrypted   = false
            # kms_key_id            = aws_iam_policy.allow_kms_key.id # module.ebs_kms_key.key_arn
            delete_on_termination = true
          }
        }
      }

      # schedules = {
      #   scale-up = {
      #     min_size     = 2
      #     max_size     = "-1" # Retains current max size
      #     desired_size = 2
      #     start_time   = "2023-03-05T00:00:00Z"
      #     end_time     = "2024-03-05T00:00:00Z"
      #     timezone     = "Etc/GMT+0"
      #     recurrence   = "0 0 * * *"
      #   },
      #   scale-down = {
      #     min_size     = 0
      #     max_size     = "-1" # Retains current max size
      #     desired_size = 0
      #     start_time   = "2023-03-05T12:00:00Z"
      #     end_time     = "2024-03-05T12:00:00Z"
      #     timezone     = "Etc/GMT+0"
      #     recurrence   = "0 12 * * *"
      #   }
      # }

      additional_tags = merge(
        var.tags,
        local.node_tags
      )

      launch_template_tags = merge(
        var.tags,
        local.node_tags
      )
    }
  }

  node_security_group_additional_rules = {
    ingress_15017 = {
      description                   = "Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }

    # Extend node-to-node security group rules. Recommended and required for the Add-ons
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # Recommended outbound traffic for Node groups
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

    # Allows Control Plane Nodes to talk to Worker nodes on all ports. Added this to avoid issues with Add-ons communication with Control plane.
    # This can be restricted further to specific port based on the requirement for each Add-on e.g., metrics-server 4443, spark-operator 8080, karpenter 8443 etc.
    # Change this according to your security requirements if needed

    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
}

#############################################
#             Kubernetes Add-ons            #
#############################################

module "eks_kubernetes_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # We want to wait for the Fargate profiles to be deployed first
  create_delay_dependencies = [for prof in module.eks.fargate_profiles : prof.fargate_profile_arn]

  eks_addons = {
    # coredns = {
    #   configuration_values = jsonencode({
    #     computeType = "Fargate"
    #     # Ensure that the we fully utilize the minimum amount of resources that are supplied by
    #     # Fargate https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html
    #     # Fargate adds 256 MB to each pod's memory reservation for the required Kubernetes
    #     # components (kubelet, kube-proxy, and containerd). Fargate rounds up to the following
    #     # compute configuration that most closely matches the sum of vCPU and memory requests in
    #     # order to ensure pods always have the resources that they need to run.
    #     resources = {
    #       limits = {
    #         cpu = "0.25"
    #         # We are targetting the smallest Task size of 512Mb, so we subtract 256Mb from the
    #         # request/limit to ensure we can fit within that task
    #         memory = "256M"
    #       }
    #       requests = {
    #         cpu = "0.25"
    #         # We are targetting the smallest Task size of 512Mb, so we subtract 256Mb from the
    #         # request/limit to ensure we can fit within that task
    #         memory = "256M"
    #       }
    #     }
    #   })
    # }

    coredns = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
      # before_compute           = true
      # service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
      # configuration_values = jsonencode({
      #   env = {
      #     # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
      #     ENABLE_PREFIX_DELEGATION = "true"
      #     WARM_PREFIX_TARGET       = "1"
      #   }
      # })
    }

    kube-proxy = {
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent = true
      # service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }

    aws-guardduty-agent = {}
  }

  # Add-ons
  enable_aws_cloudwatch_metrics       = false # Enable AWS Cloudwatch Metrics add-on for Container Insights
  enable_aws_for_fluentbit            = false
  aws_for_fluentbit_cw_log_group      = false # Let fluentbit create the cw log group
  enable_cluster_autoscaler           = false
  enable_aws_load_balancer_controller = true # This is required to expose Istio Ingress Gateway
  aws_load_balancer_controller = {
    create_namespace = true
    namespace        = "lb-controller"
    values = [jsonencode(yamldecode(<<-EOT
      clusterName: ${var.cluster_name}
    EOT
    ))]
  }
  enable_karpenter = true
  # karpenter = {
  #   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  #   repository_password = data.aws_ecrpublic_authorization_token.token.password
  # }
  enable_kube_prometheus_stack = false
  enable_metrics_server        = true
  enable_argocd                = var.enable_argocd
  # argocd = var.argocd_configuration
  argocd = {
    name          = "argocd"
    chart_version = "5.43.3"
    repository    = "https://argoproj.github.io/argo-helm"
    namespace     = "argocd"
    values = [templatefile("${path.module}/helm-chart/argocd.tftpl", {
      sshPrivateKey      = try(data.local_file.github_ssh[0].content, "")
      GIT_URL            = "https://gitlab.kyanon.digital/devops/amaze"
      base_domain        = var.base_domain
      alb_group_name     = "dev-external"
      security_group_id  = "sg-099d3898b588fafa2"
      acm_certificate_id = var.acm_certificate_id
      waf_web_acl_arn    = var.waf_web_acl_arn
      tags               = var.tags
    })]
  }

  enable_argo_rollouts  = false
  enable_argo_workflows = false
  enable_external_dns   = true
  external_dns = {
    name          = "external-dns"
    chart_version = "1.13.0"
    repository    = "https://kubernetes-sigs.github.io/external-dns/"
    namespace     = "external-dns"
    # values = [
    #   <<-EOT
    #     domainFilters = [ ${data.aws_route53_zone.this.name} ]
    #     rbac = {
    #       create = true
    #     }
    #     replicaCount = 1
    #     serviceAccount = {
    #       create = true
    #       name   = "external-dns-sa"
    #       annotations = {
    #         "eks.amazonaws.com/role-arn" = "arn:aws:iam::941121597621:role/external-dns-20230926074511232700000032"
    #       }
    #     }
    #   EOT
    # ]
    set = [
      {
        name  = "provider"
        value = "aws"
        type  = "string"
      },
      {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = var.external_dns_irsa
        type  = "string"
      },
      {
        name  = "serviceAccount.name"
        value = "external-dns-sa"
        type  = "string"
      },
      {
        name  = "domainFilters"
        value = "{${join(",", var.external_dns_domain_filters)}}"
        type  = "string"
      }
    ]
  }
  external_dns_route53_zone_arns        = [var.aws_route53_zone_arn]
  enable_cert_manager                   = true
  cert_manager_route53_hosted_zone_arns = [var.aws_route53_zone_arn]
  enable_vpa                            = false
  enable_gatekeeper                     = true

  tags = var.tags
}

data "local_file" "github_ssh" {
  count = var.enable_argocd ? 1 : 0

  filename = "${path.module}/helm-chart/github-ssh"
}

resource "aws_secretsmanager_secret" "argo_ssh_key" {
  count = var.enable_argocd ? 1 : 0

  name                    = "github-ssh-key"
  recovery_window_in_days = 0 # Set to zero for this example to force delete during Terraform destroy
}

resource "aws_secretsmanager_secret_version" "argo_ssh_key" {
  count = var.enable_argocd ? 1 : 0

  secret_id     = aws_secretsmanager_secret.argo_ssh_key[0].id
  secret_string = data.local_file.github_ssh[0].content
}

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

#############################################
#              Storage Classes              #
#############################################
resource "kubernetes_annotations" "gp2" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"

  metadata {
    name = "gp2"
  }

  annotations = {
    # Modify annotations to remove gp2 as default storage class still reatain the class
    "storageclass.kubernetes.io/is-default-class" = "false"
  }

  depends_on = [
    module.eks_kubernetes_addons
  ]
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"

    annotations = {
      # Annotation to set gp3 as default storage class
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    encrypted = true
    fsType    = "ext4"
    type      = "gp3"
  }

  depends_on = [
    module.eks_kubernetes_addons
  ]
} */
