# Usage

<!--- BEGIN_TF_DOCS --->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.47 |
| <a name="requirement_bcrypt"></a> [bcrypt](#requirement\_bcrypt) | >= 0.1.2 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.9 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.7.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.20 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.47 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | terraform-aws-modules/acm/aws | ~> 4.0 |
| <a name="module_argocd-adminpassword"></a> [argocd-adminpassword](#module\_argocd-adminpassword) | ../../modules/argocd-password | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | ../../modules/eks-argocd-cluster | n/a |
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | terraform-aws-modules/eks/aws//modules/karpenter | n/a |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | terraform-aws-modules/lambda/aws | ~> 6.0 |
| <a name="module_secrets_manager"></a> [secrets\_manager](#module\_secrets\_manager) | terraform-aws-modules/secrets-manager/aws | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/network | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configure_kubectl"></a> [configure\_kubectl](#output\_configure\_kubectl) | Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig |
| <a name="output_karpenter_aws_node_instance_profile_name"></a> [karpenter\_aws\_node\_instance\_profile\_name](#output\_karpenter\_aws\_node\_instance\_profile\_name) | n/a |
| <a name="output_karpenter_irsa_arn"></a> [karpenter\_irsa\_arn](#output\_karpenter\_irsa\_arn) | n/a |
| <a name="output_karpenter_sqs_queue_name"></a> [karpenter\_sqs\_queue\_name](#output\_karpenter\_sqs\_queue\_name) | n/a |

<!--- END_TF_DOCS --->

