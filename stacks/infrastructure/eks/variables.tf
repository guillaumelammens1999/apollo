
variable "region" {
  default = "eu-central-1"
}

variable "stack" {
  default = "eks"
}

variable "servicelevel" {
  type    = string
  default = "NOT"
}

variable "locksmith_name" {
  default = "Sentia BE:"
  type    = string
}
## Module variables

variable "cluster_version" {
  description = "(Optional) Defines the version of the cluster"
  type        = string
  default     = "1.24"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 5
}

variable "asg_min_size_schedule" {
  type    = number
  default = 2
}

variable "asg_max_size_schedule" {
  type    = number
  default = 5
}

variable "instance_type" {
  type    = string
  default = "m5.large"
}

variable "scaling_metric_statistic" {
  type    = string
  default = "Average"
}

# eks workers role

# variable "s3_admin_bucket" {}
# variable "s3_cf_sharedcontent" {}

#

variable "tags" {
  type    = map(any)
  default = {}
}

# variable "domain_name" {
#   description = "(Required) Defines the domain name for the distribution and certificates"
#   type        = string
# }

# variable "txt_owner_id" {
#   type = string
# }

# variable "domain_filters" {
#   type = list(string)
#   default = []
# }


variable "cluster_name" {
  type    = string
  default = "eks-cluster-apollo"
}

############Variables ALB Controller

variable "namespace" {
  type    = string
  default = "core-aws-lb"
}

variable "helm_version" {
  type        = string
  default     = "1.4.4" # == helm loadbalancer application version 2.4.3!
  description = "Version of the helm chart to use. See https://artifacthub.io/packages/helm/aws/aws-load-balancer-controller."
}

variable "open_id_connect_id" {
  type        = string
  description = "Provide the open_id_connect id"
  default     = "AC35F6A1B03A44F6B7C87A4D6CA40170"
}

variable "additional_options" {
  type    = map(any)
  default = {}
}

variable "domain_name" {
  default = "simplyapollo.com"
}


variable "admin_users" {
  default = ["arn:aws:iam::570752136874:user/gitlab-user"]
}