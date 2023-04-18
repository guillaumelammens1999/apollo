services = "lambda, ec2, rds"
actions  = "arn:aws:sns:eu-west-1:123456789012:sns"
log_bucket_name = "logbuckettestgui"
lambda_tag = "stable"
# deploy lambda in central region for services like cloudfront, trusted advisor
central          = true
# actions_central  = "arn:aws:sns:us-east-1:123456789012:sns"
limit_amount = "100.0"
environment = "production"