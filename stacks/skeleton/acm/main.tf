terraform {
  backend "s3" {
    bucket         = "tf-apollo-guillaume-eu-central-1"
    dynamodb_table = "tf-apollo-guillaume-eu-central-1"
    key            = "stacks/acm"
    region         = "eu-central-1"
    role_arn       = "arn:aws:iam::570752136874:role/cross_account_sharing_role"
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = local.default_static_tags

  }
  alias = "us-east-1"
}

data "aws_route53_zone" "example" {
  name         = "simplyapollo.com"
  private_zone = false
}

resource "aws_acm_certificate" "crm" {
  domain_name       = "crm.simplyapollo.com"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  provider = aws.us-east-1 
}

resource "aws_route53_record" "example" {
  for_each = {
    for dvo in aws_acm_certificate.crm.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.example.zone_id
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.crm.arn
  validation_record_fqdns = [for record in aws_route53_record.example : record.fqdn]
  provider = aws.us-east-1
}
