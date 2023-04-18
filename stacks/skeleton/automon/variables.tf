# Sentia variables

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "stack" {
  type    = string
  default = "automon"
}

variable "servicelevel" {
  type    = string
  default = "no"
}

variable "services" {}
variable "actions" {}
variable "log_bucket_name" {}
variable "lambda_tag" {}
variable "central" {}
variable "limit_amount"{
  type = number
  default =  250
}
variable "environment" {
  type = string
}


