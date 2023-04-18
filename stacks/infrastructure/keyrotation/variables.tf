variable "region" {
  default = "eu-central-1"
}

variable "stack" {
  default = "keyrotation"
}

variable "exempted_users" {
  type    = list(string)
  default = []
}
