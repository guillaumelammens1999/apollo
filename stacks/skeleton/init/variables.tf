variable "state_bucket_name" {
  default = "tf-apollo-guillaume-eu-central-1"
}

variable "state_lock_table" {
  default = "tf-apollo-guillaume-eu-central-1"
}

variable "region" {
  default = "eu-central-1"
}

variable "stack" {
  default = "init"
}


variable "sso_external_account" {
  description = "(Optional) defines if this is an external account or not"
  default     = false
  type        = bool
}

variable "sso_profiles" {
  type = map(object({
    managed_policies = list(string)
    custom_policy    = string
  }))

  default = {}
}

variable "tags" {
  default = {}
}

