terraform {
  backend "s3" {
    bucket         = "tf-apollo-guillaume-eu-central-1"
    dynamodb_table = "tf-apollo-guillaume-eu-central-1"
    key            = "stacks/keyrotation"
    region         = "eu-central-1"
    role_arn       = "arn:aws:iam::570752136874:role/cross_account_sharing_role"
  }
}

module "aws_key_rotation_iam" {
  source         = "git@gitlab.infra.be.sentia.cloud:aws/landing-zones/terraform/modules/key-rotation-iam.git?ref=v1.0.0.1"
  exempted_users = var.exempted_users
}

