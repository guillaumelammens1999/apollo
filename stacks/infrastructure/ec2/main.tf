terraform {
  backend "s3" {
    bucket         = "tf-apollo-guillaume-eu-central-1"
    dynamodb_table = "tf-apollo-guillaume-eu-central-1"
    key            = "stacks/ec2"
    region         = "eu-central-1"
    role_arn       = "arn:aws:iam::570752136874:role/cross_account_sharing_role"
  }
}

provider "aws" {
  region = "us-east-1"
  alias = "usa"
  default_tags {
    tags = local.default_static_tags

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


resource "aws_launch_template" "launch_template_apollomocktest" {
  name_prefix            = "apollotemplate"
  image_id               = "ami-005c370b8f5d3a5f5"
  instance_type          = "t4g.small"
  user_data              = filebase64("${path.module}/userdata.sh")
  vpc_security_group_ids = [aws_security_group.apollo_ec2.id]
}


##create ASG 
resource "aws_autoscaling_group" "bar" {
  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.private_subnets
  #   availability_zones = ["eu-central-1a" , "eu-central-1b"]
  desired_capacity = 2
  max_size         = 3
  min_size         = 2



  launch_template {
    id      = aws_launch_template.launch_template_apollomocktest.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Guillaume"
    propagate_at_launch = true
  }
  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]

  }
}


resource "aws_lb" "alb" {
  name                       = "gui-lb-apollo"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = data.terraform_remote_state.vpc.outputs.public_subnets
  security_groups            = [aws_security_group.apollo_alb.id]
  enable_deletion_protection = true


  tags = {
    Environment = "production"
    name        = "Guillaume"
  }
}

resource "aws_lb_target_group" "apollo_https" {
  name        = "targetgroup-apollo"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.bar.id
  lb_target_group_arn    = aws_lb_target_group.apollo_https.arn
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apollo_https.arn
  }
}


resource "aws_security_group" "apollo_alb" {
  name   = "sg_apollo"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_security_group_rule" "ingress_http_from_all_to_alb" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.apollo_alb.id
}

resource "aws_security_group_rule" "ingress_https_from_all_to_alb" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.apollo_alb.id
}

resource "aws_security_group_rule" "egress_http_alb_to_ec2" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.apollo_alb.id
  source_security_group_id = aws_security_group.apollo_ec2.id
}

resource "aws_security_group" "apollo_ec2" {
  name        = "apollo_ec2"
  description = "Apollo EC2 security group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_security_group_rule" "ingress_http_public" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.apollo_alb.id
  security_group_id        = aws_security_group.apollo_ec2.id
}

resource "aws_security_group_rule" "ingress_https_public" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.apollo_alb.id
  security_group_id        = aws_security_group.apollo_ec2.id
}
# resource "aws_security_group_rule" "egress_http" {
#   type              = "egress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   cidr_blocks       = [data.terraform_remote_state.vpc.outputs.vpc_cidr_block]
#   security_group_id = aws_security_group.apollo_ec2.id
# }

resource "aws_security_group_rule" "egress_https" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.apollo_ec2.id
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = aws_lb.alb.dns_name
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
  aliases             = ["crm.simplyapollo.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_lb.alb.dns_name

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
    target_origin_id = aws_lb.alb.dns_name

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
  domain      = "simplyapollo.com"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
  provider = aws.usa
}

data "aws_route53_zone" "simplyapollo" {
  name         = var.domain_name
  private_zone = false
  # provider = aws.us-east-1
}

resource "aws_route53_record" "alias" {
  name            = "crm"
  type            = "A"
  allow_overwrite = true
  alias {
    evaluate_target_health = true
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
  }
  zone_id = data.aws_route53_zone.simplyapollo.zone_id
}