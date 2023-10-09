variable "length" {
  type    = string
  default = 10
}
variable "override_special" {
  type    = string
  default = "!#$%&*()-_=+[]{}<>:?"
}
variable "secretsmanager_secret_name" {
  type    = string
  default = "argocd"
}
