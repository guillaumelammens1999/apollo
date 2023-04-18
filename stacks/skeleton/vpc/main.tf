terraform {
  backend "s3" {
    bucket         = "tf-apollo-guillaume-eu-central-1"
    dynamodb_table = "tf-apollo-guillaume-eu-central-1"
    key            = "stacks/vpc"
    region         = "eu-central-1"
    role_arn       = "arn:aws:iam::570752136874:role/cross_account_sharing_role"
  }
}

module "vpc" {
  source               = "git@gitlab.infra.be.sentia.cloud:provisioning/terraform/aws/modules/aws_vpc.git?ref=v2.0.0.0"
  name                 = lower(local.default_static_tags.project)
  customer             = lower(local.default_static_tags.project)
  cidr                 = var.cidr_block
  azs                  = var.azs
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets
  region               = var.region
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true
  public_subnet_tags =   var.public_subnet_tags
}

# Netbox

resource "netbox_prefix" "vpc_cidrs" {
  prefix      = var.cidr_block
  description = upper("${local.default_static_tags.customer}-${local.default_static_tags.project}-${terraform.workspace}")
  status      = "active"
  tenant_id   = data.netbox_tenant.customer.id
  vrf_id      = data.netbox_vrf.sentia_be.id
}

resource "netbox_prefix" "public" {
  count = length(var.public_subnets)

  prefix      = var.public_subnets[count.index]
  description = upper("${local.default_static_tags.customer}-${local.default_static_tags.project}-${terraform.workspace}")
  status      = "active"
  tenant_id   = data.netbox_tenant.customer.id
  vrf_id      = data.netbox_vrf.sentia_be.id
}

resource "netbox_prefix" "private" {
  count = length(var.private_subnets)

  prefix      = var.private_subnets[count.index]
  description = upper("${local.default_static_tags.customer}-${local.default_static_tags.project}-${terraform.workspace}")
  status      = "active"
  tenant_id   = data.netbox_tenant.customer.id
  vrf_id      = data.netbox_vrf.sentia_be.id
}

resource "netbox_prefix" "eks_subnets" {
  count = length(var.eks_subnets)

  prefix      = var.eks_subnets[count.index]
  description = upper("${local.default_static_tags.customer}-${local.default_static_tags.project}-${terraform.workspace}")
  status      = "active"
  tenant_id   = data.netbox_tenant.customer.id
  vrf_id      = data.netbox_vrf.sentia_be.id
}

module "eks_subnets" {
  depends_on = [module.vpc]

  vpc_id             = module.vpc.vpc_id
  source             = "git@gitlab.infra.be.sentia.cloud:aws/landing-zones/terraform/modules/aws_vpc_subnet.git?ref=v2.0.0.0"
  customer           = lower(local.default_static_tags.customer)
  stack              = var.stack
  cidr_blocks        = var.eks_subnets
  service            = "eks"
  single_nat_gateway = var.single_nat_gateway
}
