##### VPC #######

variable "vpc_name" {
  type        = string
  description = "Name to be used on all the resources as identifier"
}
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
variable "single_nat_gateway" {
  type = bool
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  default = "false"
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
variable "cidr" {
  type        = string
  description = "value of the cidr block"
}
variable "public_subnet_tags" {
  type = any
  default = {}
  description = "Public subnet tags"
}
variable "private_subnet_tags" {
  type = any
  default = {}
  description = "Private subnet tags"
}

variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  type    = string
  default = ""
}
