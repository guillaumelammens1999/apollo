provider "aws" {
  region = "eu-west-1"
  default_tags {
    tags = local.default_static_tags
  }
}

# provider "aws" {
#   region = "eu-west-1"
#   alias  = "sentinel"
#   assume_role {
#     role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/_sentia_secrets"
#   }
# }

terraform {
  required_version = "~> 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    # powerdns = {
    #   source  = "pan-net/powerdns"
    #   version = "1.5.0"
    # }
    # netbox = {
    #   source  = "e-breuninger/netbox"
    #   version = "~> 3.0.10"
    # }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2.3"
    }
  }
}

# # SSH KEY

# data "aws_secretsmanager_secret" "customer-ssh-key" {
#   arn      = "arn:aws:secretsmanager:eu-west-1:826481595599:secret:mgx-customer-ssh-key-0gDuYl"
#   provider = aws.sentinel
# }

# data "aws_secretsmanager_secret_version" "customer-ssh-key" {
#   secret_id = data.aws_secretsmanager_secret.customer-ssh-key.id
#   provider  = aws.sentinel
# }

# # NETBOX

# provider "netbox" {
#   server_url           = "https://netbox.infra.be.sentia.cloud"
#   api_token            = data.aws_secretsmanager_secret_version.netbox-api.secret_string
#   allow_insecure_https = true
# }

# data "aws_secretsmanager_secret" "netbox-api" {
#   arn      = "arn:aws:secretsmanager:eu-west-1:826481595599:secret:sentia-secret-netbox-api-XoKljR"
#   provider = aws.sentinel
# }

# data "aws_secretsmanager_secret_version" "netbox-api" {
#   secret_id = data.aws_secretsmanager_secret.netbox-api.id
#   provider  = aws.sentinel
# }

# POWERDNS

# provider "powerdns" {
#   api_key    = data.aws_secretsmanager_secret_version.powerdns.secret_string
#   server_url = "http://dnsadmin.infra.be.sentia.cloud:8081"
# }

# data "aws_secretsmanager_secret" "powerdns" {
#   arn      = "arn:aws:secretsmanager:eu-west-1:826481595599:secret:sentia-secret-powerdns-api-pOxvgD"
#   provider = aws.sentinel
# }

# data "aws_secretsmanager_secret_version" "powerdns" {
#   secret_id = data.aws_secretsmanager_secret.powerdns.id
#   provider  = aws.sentinel
# }

# # ENIGMA

# data "aws_secretsmanager_secret" "enigma" {
#   arn      = "arn:aws:secretsmanager:eu-west-1:826481595599:secret:sentia-secret-enigma-api-rnoeX9"
#   provider = aws.sentinel
# }

# data "aws_secretsmanager_secret_version" "enigma" {
#   secret_id = data.aws_secretsmanager_secret.enigma.id
#   provider  = aws.sentinel
# }

## LOCALS
locals {
  default_static_tags = {
    project         = "{{ project }}"
    customer        = "{{ customer }}"
    workspace       = terraform.workspace
    terraform       = "1.3"
    locksmith_name  = "Locksmith name"
    stack           = var.stack
    region          = var.region
    create_alert    = "true"
    serviceLevel    = terraform.workspace == "acceptance" ? "NC" : var.stack == "documentation" ? "NO" : "MC"
    contractNumber  = "CON-xxxxxxx"
    accountNumber   = "ACC-xxxxxxx"
    environmentType = upper(terraform.workspace)
    billingCode     = "CON-xxxxxxx"
  }
}
 
data "aws_caller_identity" "current" {}
