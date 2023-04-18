terraform {
  backend "s3" {
    bucket         = "tf-apollo-guillaume-eu-central-1"
    dynamodb_table = "tf-apollo-guillaume-eu-central-1"
    key            = "stacks/route53"
    region         = "eu-central-1"
    role_arn       = "arn:aws:iam::570752136874:role/cross_account_sharing_role"
  }
}

#importRoute53HostedZone
resource "aws_route53_zone" "SimplyApollo" {
  name = "simplyapollo.com"

  tags = {
    Guillaume = true 
  }
}

# resource "aws_elb" "main" {
#   name               = "elb-simply-apollo"
#   availability_zones = ["eu-central-1", ]

#   listener {
#     instance_port     = 80
#     instance_protocol = "http"
#     lb_port           = 80
#     lb_protocol       = "http"
#   }
# }

