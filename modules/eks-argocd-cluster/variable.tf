#### provider Variables defined #######
variable "region" {
  type        = string
  description = "Name of the region to deploy infra"
  default     = "ap-southeast-1"
}

##### VPC #######

variable "public_subnets" {
  type        = list(string)
  description = "A list of public subnets inside the VPC"
  default     = []
}
variable "private_subnets" {
  type        = list(string)
  description = "A list of private subnets inside the VPC"
  default     = []
}

variable "azs" {
  type        = list(string)
  description = "A list of availability zones specified as argument to this module"
  default     = []
}
variable "enable_nat_gateway" {
  type        = bool
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  default     = "false"
}
variable "enable_vpn_gateway" {
  type        = bool
  description = "Should be true if you want to create a new VPN Gateway resource and attach it to the VPC"
  default     = "false"
}

variable "one_nat_gateway_per_az" {
  type        = bool
  description = "Should be true if you want only one NAT Gateway per availability zone"
  default     = "false"
}
variable "enable_dns_hostnames" {
  type        = bool
  description = "Should be true to enable DNS hostnames in the VPC"
  default     = "true"
}
variable "enable_dns_support" {
  type        = bool
  description = "Should be true to enable DNS support in the VPC"
  default     = "true"
}
variable "vpc_tags" {
  type = map(string)
  default = {
    Terraform   = "true"
    Environment = "production"
  }
}

variable "public_subnet_tags" {
  type        = any
  default     = {}
  description = "Public subnet tags"
}
variable "private_subnet_tags" {
  type        = any
  default     = {}
  description = "Private subnet tags"
}
variable "vpc_id" {
  type = string
}
variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
  default     = []
}



##### EKS #######
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "cluster_version" {
  type        = string
  description = "version of the EKS cluster"
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  default     = "true"
}
variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  default     = "false"
}
variable "enable_irsa" {
  type        = bool
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA"
  default     = "true"
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "create_cloudwatch_log_group" {
  type    = bool
  default = "false"
}
variable "cluster_addons" {
  type    = any
  default = {}
}

variable "eks_managed_node_groups" {
  type    = any
  default = {}
}

variable "load-balancer-controller-enabled" {
  type        = bool
  description = "Should be true if you want to deploy load-balancer-controller role"
}
variable "karpenter-enabled" {
  type        = bool
  description = "Should be true if you want to deploy karpenter role"
}

variable "external_secrets" {
  type        = bool
  description = "Should be true if you want to deploy external-secrets role"
}
variable "cluster_security_group_additional_rules" {
  type = any
  default = {}
}
variable "node_security_group_additional_rules" {
  type = any
  default = {}
}
variable "manage_aws_auth_configmap" {
  type = bool
  
}
variable "aws_auth_roles" {
  type = any
}
variable "node_security_group_tags" {
  type = any
}

##### ArgoCD #######
variable "enable_argocd" {
  type        = bool
  default     = false
  description = "Should be true if you want to deploy ArgoCD"
}
variable "argocd_manage_add_ons" {
  type        = bool
  default     = false
  description = "Indicates that ArgoCD is responsible for managing/deploying add-ons"
}
variable "argocd_helm_config" {
  type        = any
  default     = {}
  description = "ArgoCD Helm configuration"
}
variable "argocd_applications" {
  type        = any
  default     = {}
  description = "ArgoCD Applications like workload and platform"
}

variable "karpenter_subnet_account_id" {
  description = "Account ID of where the subnets Karpenter will utilize resides. Used when subnets are shared from another account"
  type        = string
  default     = ""
}

variable "karpenter_controller_ssm_parameter_arns" {
  description = "List of SSM Parameter ARNs that contain AMI IDs launched by Karpenter"
  type        = list(string)
  default = ["arn:aws:ssm:*:*:parameter/aws/service/*"]
}

variable "karpenter_controller_node_iam_role_arns" {
  description = "List of node IAM role ARNs Karpenter can use to launch nodes"
  type        = list(string)
  default     = ["*"]
}

variable "karpenter_sqs_queue_arn" {
  description = "(Optional) ARN of SQS used by Karpenter when native node termination handling is enabled"
  type        = string
  default     = null
}

variable "policy_name_prefix" {
  description = "IAM policy name prefix"
  type        = string
  default     = "AmazonEKS_"
}
