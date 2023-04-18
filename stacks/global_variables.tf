provider "aws" {
  region = local.default_static_tags.region
  default_tags {
    tags = local.default_static_tags

  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "sentinel"
  assume_role {
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/_sentia_secrets"
  }
  default_tags {
    tags = local.default_static_tags
  }
}

terraform {
  required_version = "~> 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4"
    }
    powerdns = {
      source  = "pan-net/powerdns"
      version = "1.5.0"
    }
    netbox = {
      source  = "e-breuninger/netbox"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.13.0"
    }
  }
}

locals {
  default_static_tags = {
    customer        = "apollo"
    project         = "apollo-mock"
    region          = "eu-central-1"
    stack           = var.stack
    terraform       = "1.3"
    workspace       = terraform.workspace
    serviceLevel    = terraform.workspace == "acceptance" ? "NC" : "MC"
    environmentType = upper(terraform.workspace)
    CREATE_ALERT    = true
    locksmith_name  = "apollo"
  }
}

data "aws_caller_identity" "current" {}

# NETBOX

data "netbox_tenant" "customer" {
  name = "be.sentia"
}

data "netbox_vrf" "sentia_be" {
  name = "SentiaBE"
}

provider "netbox" {
  server_url           = "https://netbox.infra.be.sentia.cloud"
  api_token            = data.aws_secretsmanager_secret_version.netbox-api.secret_string
  allow_insecure_https = true
}

data "aws_secretsmanager_secret" "netbox-api" {
  arn      = "arn:aws:secretsmanager:eu-west-1:826481595599:secret:sentia-secret-netbox-api-XoKljR"
  provider = aws.sentinel
}

data "aws_secretsmanager_secret_version" "netbox-api" {
  secret_id = data.aws_secretsmanager_secret.netbox-api.id
  provider  = aws.sentinel
}

# POWERDNS

provider "powerdns" {
  api_key    = data.aws_secretsmanager_secret_version.powerdns.secret_string
  server_url = "http://dnsadmin.infra.be.sentia.cloud:8081"
}

data "aws_secretsmanager_secret" "powerdns" {
  arn      = "arn:aws:secretsmanager:eu-west-1:826481595599:secret:sentia-secret-powerdns-api-pOxvgD"
  provider = aws.sentinel
}

data "aws_secretsmanager_secret_version" "powerdns" {
  secret_id = data.aws_secretsmanager_secret.powerdns.id
  provider  = aws.sentinel
}
