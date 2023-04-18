#terraform {
#  backend "s3" {
#    bucket   = "tf-{{ customer | lower }}-{{ region }}"
#    key      = "stacks/{{ stack | lower }}"
#    region   = "{{ region }}"
#    role_arn = "arn:aws:iam::{{ account }}:role/cross_account_sharing_role"
#  }
#}
