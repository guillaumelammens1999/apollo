terraform {
  backend "s3" {
    bucket         = "tf-apollo-guillaume-eu-central-1"
    dynamodb_table = "tf-apollo-guillaume-eu-central-1"
    key            = "stacks/s3"
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

module "aws_s3_mybucket"  {
  source                                = "git@gitlab.infra.be.sentia.cloud:aws/landing-zones/terraform/modules/aws_s3/aws_s3_bucket.git"
  bucket                                = var.bucket_name
  versioning                            = var.mybucket_versioning
  ##Tags niet op localdefaulttags
  tags                                  = {}
  lifecycle_rule                        = var.mybucket_lifecycle_rule
  server_side_encryption_configuration  = var.mybucket_server_side_encryption_configuration
}

resource "aws_s3_bucket" "crmbucketcontent" {
  bucket = "crmbucketcontentapollo"
  acl = "private"
}

# resource "aws_s3_bucket_policy" "crmbucketpolicy" {
#   bucket = module.aws_s3_mybucket.id
#   policy = jsonencode({
#     Version = "2012-10-17",
#     	"Statement": [
# 		{
# 			"Sid": "AllowCloudFrontServicePrincipalReadOnly",
# 			"Effect": "Allow",
# 			"Principal": {
# 				"Service": "cloudfront.amazonaws.com"
# 			},
# 			"Action": "s3:GetObject",
# 			"Resource": "arn:aws:s3:::${module.aws_s3_mybucket.id}/*",
# 			"Condition": {
# 				"StringEquals": {
# 					"AWS:SourceArn": aws_cloudfront_distribution.s3_distribution.arn
# 				}
# 			}
# 		}
# 	]
#   })
# }

resource "aws_s3_object" "index_object" {
    bucket = module.aws_s3_mybucket.id
    key = "index.html"
    source = "./html/index.html"
}

resource "aws_s3_object" "error_object" {
    bucket = module.aws_s3_mybucket.id
    key = "error.html"
    source = "./html/error.html"
}

resource "aws_s3_bucket_policy" "gui-website-policy" {
  bucket = module.aws_s3_mybucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    	"Statement": [
		{
			"Sid": "AllowCloudFrontServicePrincipalReadOnly",
			"Effect": "Allow",
			"Principal": {
				"Service": "cloudfront.amazonaws.com"
			},
			"Action": "s3:GetObject",
			"Resource": "arn:aws:s3:::${module.aws_s3_mybucket.id}/*",
			"Condition": {
				"StringEquals": {
					"AWS:SourceArn": aws_cloudfront_distribution.s3_distribution.arn
				}
			}
		}
	]
  })
}

resource "aws_s3_bucket_acl" "b_acl" {
  bucket = module.aws_s3_mybucket.id
  acl    = "private"
}


#Origina Access
resource "aws_cloudfront_origin_access_control" "OAIDistribution" {
  name                              = "example"
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

}


resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = module.aws_s3_mybucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.OAIDistribution.id
    origin_id                = "s3origin"
  }


  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  # logging_config {
  #   include_cookies = false
  #   bucket          = "mylogs.s3.amazonaws.com"
  #   prefix          = "myprefix"
  # }

  aliases = ["simplyapollo.com", "www.simplyapollo.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3origin"

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
    path_pattern     = "/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "s3origin"

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
   acm_certificate_arn            =  data.aws_acm_certificate.amazon_issued.arn
   ssl_support_method = "sni-only"
  }
 
}

data "aws_acm_certificate" "amazon_issued" {
  domain      = var.domain_name
  types       = ["AMAZON_ISSUED"]
  most_recent = true
  provider = aws.us-east-1
}

data "aws_route53_zone" "simplyapollo" {
  name         = "simplyapollo.com"
  private_zone = false
  # provider = aws.us-east-1
}

resource "aws_route53_record" "alias" {
  name            = "simplyapollo.com"
  type            = "A"
  allow_overwrite = true
  alias {
    evaluate_target_health = true
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
  }
  zone_id = data.aws_route53_zone.simplyapollo.zone_id
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.simplyapollo.zone_id
  name    = "www"
  type    = "CNAME"
  records        = ["simplyapollo.com"]
  ttl = 300

}