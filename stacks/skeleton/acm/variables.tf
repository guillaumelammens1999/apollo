variable "stack" {
  type    = string
  default = "acm"
}

variable "servicelevel" {
  type = string
  default= "NO"
}

variable "root_domain_name" {
  type    = string
  default = "simplyapollo.com"
}

variable "region" {
  type = string
  default = "eu-central-1"
}