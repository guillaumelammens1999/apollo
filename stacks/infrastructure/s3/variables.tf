variable "mybucket_versioning" {
  default = { "enabled" : true }
  type    = map(any)
}

variable "mybucket_lifecycle_rule" {
  default = []
  type    = any
}

variable "mybucket_server_side_encryption_configuration" {
  default = {}
  type    = map(map(map(any)))
}

variable "bucket_name" {
  default = "gui-website-bucket"
  type    = string
}

##Vereist

variable "region" {
  default = "eu-central-1"
}

variable "stack" {
  default = "s3"
}

variable "domain_name" {
  default = "simplyapollo.com"
}