# Usage

<!--- BEGIN_TF_DOCS --->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_bcrypt"></a> [bcrypt](#requirement\_bcrypt) | >= 0.1.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_bcrypt"></a> [bcrypt](#provider\_bcrypt) | >= 0.1.2 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.argocd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.argocd](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [bcrypt_hash.argo](https://registry.terraform.io/providers/viktorradnai/bcrypt/latest/docs/resources/hash) | resource |
| [random_password.argocd](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_length"></a> [length](#input\_length) | n/a | `string` | `10` | no |
| <a name="input_override_special"></a> [override\_special](#input\_override\_special) | n/a | `string` | `"!#$%&*()-_=+[]{}<>:?"` | no |
| <a name="input_secretsmanager_secret_name"></a> [secretsmanager\_secret\_name](#input\_secretsmanager\_secret\_name) | n/a | `string` | `"argocd"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bcrypt_hash"></a> [bcrypt\_hash](#output\_bcrypt\_hash) | n/a |

<!--- END_TF_DOCS --->

