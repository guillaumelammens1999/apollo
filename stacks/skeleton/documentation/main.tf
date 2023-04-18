terraform {
  backend "s3" {
    bucket         = "tf-apollo-guillaume-eu-central-1"
    dynamodb_table = "tf-apollo-guillaume-eu-central-1"
    key            = "stacks/documentation"
    region         = "eu-central-1"
    role_arn       = "arn:aws:iam::570752136874:role/cross_account_sharing_role"
  }
}

provider "aws" {
  region = var.region
  alias  = "terraform_repo_account"
  assume_role {
    role_arn     = "arn:aws:iam::120250115268:role/iam-autodoc-allow-acm-validation"
    session_name = "r53_access"
    external_id = "gvhf0Bgv20xH"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket   = "tf-apollo-guillaume-eu-central-1"
    key      = join("/", ["env:", terraform.workspace, "stacks/vpc"])
    region   = "eu-central-1"
    role_arn = "arn:aws:iam::570752136874:role/cross_account_sharing_role"
  }
}


data "aws_subnet_ids" "private" {
  filter {
    name   = "tag:Name"
    values = ["*${local.default_static_tags.project}-private*"]
  }
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}


module "documentation" {
  source           = "git@gitlab.infra.be.sentia.cloud:aws/landing-zones/terraform/modules/aws_autodoc_infra?ref=v0.0.0.2"
  region           = var.region
  project          = var.project
  dns_prefix       = "apollo-guillaume"
  vpc_id           = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids       = data.terraform_remote_state.vpc.outputs.public_subnets
  providers = {
    aws.local   = aws
    aws.route53_account = aws.terraform_repo_account
  }
}

