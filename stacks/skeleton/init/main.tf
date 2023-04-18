terraform {
  backend "s3" {
    bucket         = "tf-apollo-guillaume-eu-central-1"
    dynamodb_table = "tf-apollo-guillaume-eu-central-1"
    key            = "stacks/init"
    region         = "eu-central-1"
    role_arn       = "arn:aws:iam::570752136874:role/cross_account_sharing_role"
  }
}
module "init" {
  source                    = "git@gitlab.infra.be.sentia.cloud:/aws/landing-zones/terraform/modules/aws_init?ref=v1.1.1.4"
  project                   = local.default_static_tags.project
  region                    = local.default_static_tags.region
  customer                  = local.default_static_tags.customer
  state_bucket_name         = var.state_bucket_name
  state_lock_table          = var.state_lock_table
  aws_account_id_list       = ["570752136874"]
  sharedservices_account_id = "570752136874"
  sentinel_account_id       = "471916516063"
  service_account           = "production"
  sso_external_account      = var.sso_external_account
  sso_profiles              = var.sso_profiles
  tags                      = var.tags
}


 resource "aws_secretsmanager_secret" "gitlab_user" {
  name = "gitlab-user"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.gitlab_user.id
  secret_string = "{${ module.init.access_id} and ${ module.init.secret}}"
}