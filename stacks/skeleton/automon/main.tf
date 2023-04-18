terraform {
  backend "s3" {
    bucket         = "tf-apollo-guillaume-eu-central-1"
    dynamodb_table = "tf-apollo-guillaume-eu-central-1"
    key            = "stacks/automon"
    region         = "eu-central-1"
    role_arn       = "arn:aws:iam::570752136874:role/cross_account_sharing_role"
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "central"
  default_tags {
    tags = local.default_static_tags
  }
}


module "automonitoring" {
 source  = "git@gitlab.infra.be.sentia.cloud:aws/landing-zones/terraform/modules/aws_automonitoring.git//module?ref=v1.0.0.0"
 
  actions         = var.actions
  services        = var.services
  lambda_tag      = var.lambda_tag
  log_bucket_name = var.log_bucket_name
  central         = var.central
  tags            = local.default_static_tags
  limit_amount = var.limit_amount
  environment = var.environment
  providers =   {
    aws.central = aws.central
    aws.local = aws 
    }
}
