#use the latest version of the INIT module
provider "aws" {
  region = var.region
  alias  = "ssv"
  assume_role {
    role_arn = "arn:aws:iam::SSV_ACCOUNT_ID:role/cross_account_sharing_role"
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "usa"
  default_tags {
    tags = local.default_static_tags

  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}


data "aws_iam_roles" "admin" {
  name_regex = ".*Administrator.*"
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
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

locals {
  eks_default_enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingCapacity",
    "GroupPendingInstances",
    "GroupStandbyCapacity",
    "GroupStandbyInstances",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances",
  ]

  # default_static_tags = {
  #   customer        = "apollo"
  #   project         = "apollo-mock"
  #   region          = "eu-central-1"
  #   stack           = var.stack
  #   terraform       = "1.3"
  #   workspace       = terraform.workspace
  #   serviceLevel    = terraform.workspace == "acceptance" ? "NC" : "MC"
  #   environmentType = upper(terraform.workspace)
  #   CREATE_ALERT    = true
  #   locksmith_name  = "apollo"
  # }
  issuer_no_url = replace(data.aws_iam_openid_connect_provider.openidconnect.url, "https://", "")
  issuer_url    = module.eks.cluster_oidc_issuer_url
}

data "aws_iam_openid_connect_provider" "openidconnect" {
  url = local.issuer_url
}

terraform {
  backend "s3" {
    bucket         = "tf-apollo-guillaume-eu-central-1"
    dynamodb_table = "tf-apollo-guillaume-eu-central-1"
    key            = "stacks/eks"
    region         = "eu-central-1"
    role_arn       = "arn:aws:iam::570752136874:role/cross_account_sharing_role"
  }
}

module "aws_lb" {
  source             = "git@gitlab.infra.be.sentia.cloud:aws/landing-zones/terraform/modules/eks_plugins/aws_load_balancer_controller.git?ref=v2.4.3.2"
  cluster_name       = var.cluster_name
  open_id_connect_id = module.eks.cluster_oidc_issuer_url
}

resource "aws_cloudfront_distribution" "lb" {
  origin {
    domain_name = "k8s-crmtest-ingressd-1eabe9b84d-206093904.eu-central-1.elb.amazonaws.com"
    origin_id   = "k8s-crmtest-ingressd-1eabe9b84d-206093904.eu-central-1.elb.amazonaws.com"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }


  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"
  aliases             = ["crmm.simplyapollo.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "k8s-crmtest-ingressd-1eabe9b84d-206093904.eu-central-1.elb.amazonaws.com"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "k8s-crmtest-ingressd-1eabe9b84d-206093904.eu-central-1.elb.amazonaws.com"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # # Cache behavior with precedence 1
  # ordered_cache_behavior {
  #   path_pattern     = "/content/*"
  #   allowed_methods  = ["GET", "HEAD", "OPTIONS"]
  #   cached_methods   = ["GET", "HEAD"]
  #   target_origin_id = "s3origin"

  #   forwarded_values {
  #     query_string = false

  #     cookies {
  #       forward = "none"
  #     }
  #   }

  #   min_ttl                = 0
  #   default_ttl            = 3600
  #   max_ttl                = 86400
  #   compress               = true
  #   viewer_protocol_policy = "redirect-to-https"
  # }

  # price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.amazon_issued.arn
    ssl_support_method  = "sni-only"
  }

}

data "aws_acm_certificate" "amazon_issued" {
  domain      = var.domain_name
  types       = ["AMAZON_ISSUED"]
  most_recent = true
  provider    = aws.usa
}

data "aws_route53_zone" "simplyapollo" {
  name         = "simplyapollo.com"
  private_zone = false
  # provider = aws.us-east-1
}

resource "aws_route53_record" "alias" {
  name = "crmm"
  type = "A"

  allow_overwrite = true
  alias {
    evaluate_target_health = true
    name                   = aws_cloudfront_distribution.lb.domain_name
    zone_id                = aws_cloudfront_distribution.lb.hosted_zone_id
  }
  zone_id = data.aws_route53_zone.simplyapollo.zone_id
}


module "eks" {
  source       = "git::ssh://git@gitlab.infra.be.sentia.cloud/aws/landing-zones/terraform/modules/aws_eks.git?ref=v2.0.6"
  admin_users  = var.admin_users
  cluster_name = var.cluster_name
  subnets = [
    data.terraform_remote_state.vpc.outputs.private_subnets[0],
    data.terraform_remote_state.vpc.outputs.private_subnets[1],
  ]
  vpc_id                                = data.terraform_remote_state.vpc.outputs.vpc_id
  cluster_version                       = "1.24"
  cluster_endpoint_private_access       = true
  cluster_endpoint_public_access        = true
  worker_create_initial_lifecycle_hooks = false

  encrypt_cluster_secrets           = true
  cluster_secret_encryption_key_arn = "" # creates a new one

  worker_groups = [
    {
      name                 = "infrapollo"
      instance_type        = "m5.large"
      autoscaling_enabled  = false
      ebs_optimized        = true
      asg_min_size         = 1
      asg_desired_capacity = 3
      asg_max_size         = 4
      root_volume_size     = 20
      disk_size            = 50
      termination_policies = ["OldestInstance"]
      enabled_metrics      = local.eks_default_enabled_metrics
      # market_type          = "spot" # This creates spot instances.
    },
  ]
  # map_users = [
  #   {
  #     userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/gitlab-user"
  #     username = "gitlab-user"
  #     groups   = ["system:masters"]
  #   }
  # ]
  sentia_mgmt_security_group_name = "Sentia MGT"

  tags                             = { "create_alert" = true }
  create_openidp_in_sharedservices = false

  providers = {
    aws     = aws
    aws.ssv = aws # replace with ssv provider
  }

  depends_on = [aws_security_group.sentia_mgt]
}


resource "aws_security_group" "sentia_mgt" {
  name        = "Sentia MGT"
  description = "Sentia Management security group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_security_group_rule" "allow_mgt_traffic" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sentia_mgt.id
}
resource "aws_security_group_rule" "allow_mgt_icmp" {
  type              = "ingress"
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = -1
  to_port           = -1
  security_group_id = aws_security_group.sentia_mgt.id
}

resource "aws_security_group" "remote-connect" {
  name   = "remote-connect-access"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_security_group_rule" "outgoing-https" {
  from_port         = 443
  protocol          = "TCP"
  security_group_id = aws_security_group.remote-connect.id
  to_port           = 443
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "incoming-https" {
  from_port         = 443
  protocol          = "TCP"
  security_group_id = aws_security_group.remote-connect.id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

#Plugin CoreDNS

resource "aws_eks_addon" "coredns" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "coredns"
  addon_version     = "v1.9.3-eksbuild.2"
  resolve_conflicts = "OVERWRITE"

  configuration_values = jsonencode({})
  depends_on           = [module.eks, module.vpc_cni]
}


# data "tls_certificate" "oidc" {
#   url = module.eks.cluster_oidc_issuer_url
# }


# module "external_dns" {
#   source                             = "git@gitlab.infra.be.sentia.cloud:aws/landing-zones/terraform/modules/eks_plugins/external_dns.git?ref=v0.10.2"
#   cluster_name                       = module.eks.cluster_id
#   region                             = var.region
#   txt_owner_id                       = var.txt_owner_id
#   domain_filters                     = var.domain_filters
#   openid_connect_provider_url        = module.eks.cluster_oidc_issuer_url
#   openid_connect_provider_thumbprint = data.tls_certificate.oidc.certificates.0.sha1_fingerprint
#   providers = {
#     aws.ssv = aws.route53_account
#   }

# }

module "cluster_autoscaler" {
  source             = "git@gitlab.infra.be.sentia.cloud:aws/landing-zones/terraform/modules/eks_plugins/cluster_autoscaler.git?ref=v1.25.0"
  cluster_name       = module.eks.cluster_id
  open_id_connect_id = module.eks.cluster_oidc_issuer_url
  region             = var.region
  memory_limit       = "800Mi"
  additional_options = {
    "image.tag" = "v1.25.0"
  }
}

# module "fluent_bit" {
#   source                      = "git::ssh://git@gitlab.infra.be.sentia.cloud/aws/landing-zones/terraform/modules/eks_plugins/fluent_bit.git?ref=v0.1.19"
#   cluster_name                = module.eks.cluster_id
#   region                      = var.region
#   openid_connect_provider_url = module.eks.cluster_oidc_issuer_url
#   helm_version                = "v0.1.23"
#   additional_options = {
#     "image.tag" = "2.31.5"
#     #"cloudWatch.logStreamName" = "$(kubernetes['container_name'])",
#     #"input.DockerMode"      = "Off",
#     #"input.Multiline"       = "On",
#     #"input.ParserFirstline" = "multiline"
#     #"service.extraParsers"  = "[PARSER]\n    Name              multiline\n    Format            regex\n    Regex             /(?<time>Dec \\d+ \\d+\\:\\d+\\:\\d+)(?<message>.*)/\n    Time_Key          time\n    Time_Format       %b %d %H:%M:%S"
#   }

#   providers = {
#     aws.cwlogs = aws
#   }
# }



# module "metrics_server" {
#   source       = "git::ssh://git@gitlab.infra.be.sentia.cloud/aws/landing-zones/terraform/modules/eks_plugins/metrics_server.git?ref=v3.8.2.2"
#   cluster_name = module.eks.cluster_id
#   helm_version = "3.8.3"
#   depends_on   = [module.eks, module.vpc_cni]
# }


# VPC-CNI

module "vpc_cni" {
  source                      = "git@gitlab.infra.be.sentia.cloud:aws/landing-zones/terraform/modules/eks_plugins/vpc_cni.git?ref=v1.3"
  cluster_name                = module.eks.cluster_id
  openid_connect_id           = data.aws_iam_openid_connect_provider.openidconnect.id
  openid_connect_provider_url = data.aws_iam_openid_connect_provider.openidconnect.url
  vpc_cni_version             = "v1.12.2-eksbuild.1"

  dynamic_resource_tags     = local.default_static_tags
  depends_on                = [module.eks]
  vpc_id                    = data.terraform_remote_state.vpc.outputs.vpc_id
  cluster_security_group_id = module.eks.cluster_security_group_id
  worker_security_group_id  = module.eks.worker_security_group_id
  vpc_cidr_ranges           = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
}

# KUBE-PROXY

resource "aws_eks_addon" "kube-proxy" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "kube-proxy"
  addon_version     = "v1.24.7-eksbuild.2"
  resolve_conflicts = "OVERWRITE"
  depends_on        = [module.eks, module.vpc_cni]
}


# module "external_dns" {
#   source                             = "git@gitlab.infra.be.sentia.cloud:aws/landing-zones/terraform/modules/eks_plugins/external_dns.git?ref=v1.11.0.2"
#   cluster_name                       = module.eks.cluster_id
#   region                             = var.region
#   txt_owner_id                       = "Z00376311S6FNQMRZEQ27"
#   domain_filters                     = ["simplyapollo.com"]
#   openid_connect_provider_url        = module.eks.cluster_oidc_issuer_url
#   openid_connect_provider_thumbprint = data.tls_certificate.oidc.certificates.0.sha1_fingerprint
#   providers = {
#     aws.ssv = aws.ssv
#   }

# }
