## Sentia variables

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "stack" {
  type    = string
  default = "vpc"
}

variable "servicelevel" {
  type    = string
  default = "NO"
}

## VPC vars

variable "cidr_block" {
  type    = string
  default = "10.100.10.0/24"
}

variable "azs" {
  description = "The names of the azs in which you want to deploy"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.100.10.128/27", "10.100.10.160/27"]
}
variable "public_subnets" {
  type    = list(string)
  default = ["10.100.10.192/27", "10.100.10.224/27"]
}

variable "eks_subnets" {
  type    = list(string)
  default = ["10.100.10.0/26", "10.100.10.64/26"]
}

variable "enable_nat_gateway" {
  default = true
  type    = bool
}

variable "single_nat_gateway" {
  default = false
  type    = bool
}

variable "public_subnet_tags" {
  type        = map(string)
  default     = { 
    "kubernetes.io/role/elb" = ""
    }
}