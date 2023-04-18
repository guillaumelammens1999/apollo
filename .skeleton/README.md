# Customer skeleton

The script will generate a base set of templates for a new customer deployment
for terraform with directories and files for 


``` bash
$ pip3 install -r requirements.txt
$ python3 generate_tf.py -h

usage: generate_tf.py [-h] [--git-path GIT] [--template-path TEMPLATE] [-f TF_FILES [TF_FILES ...]] [--config YAML_CONFIG] [--force]

Sentia init

optional arguments:
  -h, --help            show this help message and exit
  --git-path GIT        path to put newly created terraform files - default: './'
  --template-path TEMPLATE
                        path where templates are located - default: 'templates/'
  -f TF_FILES [TF_FILES ...], --files TF_FILES [TF_FILES ...]
                        a list of stacks.
  --config YAML_CONFIG  this configfile superseeds other parameters like account, customer, project and stack
  --force               forces recreationg of files
```

## Example config file

``` yaml
account: 12345678901
region: eu-west-1
customer: Sentia
project: test-project-1
stacks:
  skeleton:
    - init
    - vpc
    - monitoring
    - client_vpn
    - acm_create
    - acm_validate
    - route53
  applications:
    - eks

provider: 3.38.0
terraform: 0.14.7
```

run the script

``` bash
python3 generate_tf.py --config example_config.yaml
```

## Outputs generated

directory and folder structure

``` bash
$ tree stacks/
stacks/
├── applications
│   └── eks
│       ├── alb_ingress_helm.tf
│       ├── base_variables.tf
│       ├── eks.tf
│       ├── global_variables.tf -> ../../global_variables.tf
│       ├── iam_user_eks.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── provider.tf
│       └── variables.tf
├── global_variables.tf
└── skeleton
    ├── acm_create
    │   ├── acm_create.tf
    │   ├── base_variables.tf
    │   ├── global_variables.tf -> ../../global_variables.tf
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── acm_validate
    │   ├── acm_validate.tf
    │   ├── base_variables.tf
    │   ├── global_variables.tf -> ../../global_variables.tf
    │   ├── main.tf
    │   └── variables.tf
    ├── client_vpn
    │   ├── base_variables.tf
    │   ├── client_vpn.tf
    │   ├── global_variables.tf -> ../../global_variables.tf
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── init
    │   ├── base_variables.tf
    │   ├── cicd_secret.tf
    │   ├── global_variables.tf -> ../../global_variables.tf
    │   ├── init.tf
    │   ├── main.tf
    │   └── variables.tf
    ├── monitoring
    │   ├── base_variables.tf
    │   ├── global_variables.tf -> ../../global_variables.tf
    │   ├── main.tf
    │   ├── monitoring.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── route53
    │   ├── base_variables.tf
    │   ├── global_variables.tf -> ../../global_variables.tf
    │   ├── main.tf
    │   ├── outputs.tf
    │   ├── route53.tf
    │   └── variables.tf
    └── vpc
        ├── base_variables.tf
        ├── global_variables.tf -> ../../global_variables.tf
        ├── main.tf
        ├── outputs.tf
        ├── sentia_sg.tf
        ├── ssm.tf
        ├── tgw.tf
        ├── variables.tf
        └── vpc.tf

10 directories, 54 files
```

output in main.tf file from init stack

``` 
provider "aws" {
  region  = var.region
}

terraform {
  required_version = "~> 0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.38.0"
    }
  }
  backend "s3" {
    bucket   = "tf-sentia-eu-west-1"
    key      = "stacks/init"
    region   = "eu-west-1"
    role_arn = "arn:aws:iam::12345678901:role/cross_account_sharing_role"
  }
}

##

# data "terraform_remote_state" "vpc" {
#   backend = "s3"
#   config = {
#     bucket   = "tf-sentia-eu-west-1"
#     key      = join("/", ["env:", terraform.workspace, "stacks/vpc"])
#     region   = "eu-west-1"
#     role_arn = "arn:aws:iam::12345678901:role/cross_account_sharing_role"
#   }
# }
```
