# Whitepaper BE AWS MOCK Exercise - ASG version
## Scope of Exercise
A company called 'Apollo Space Services' specialised in custom carbon dioxide filters for the aviation and aerospace industry has requested Sentia / Accenture to host their public website and CRM application on AWS.
The public website will be hosted on S3 with CloudFront as CDN service. All S3 buckets should be encrypted and no public access is allowed.

The CRM application will run in an Auto-scaling Group spread across two Availability Zones.
The website will be provided by the customer as a ZIP.


Sentia / Accenture will build and support the environment, providing a mission-critical SLA.

You as an AWS Cloud Engineer have been instructed by your manager to handle this project.
Use your AWS knowledge, Sentia documentation and the help from your colleagues to finished this assignment.
## Learning Goals
- Basics of AWS using awscli
- Basics of Terraform for provisioning the AWS resources

## Acceptance criteria
Source files: https://gitlab.infra.be.sentia.cloud/aws/be/projects/aws-mock-exercise

Create the project, terraform folder and file structure conform the guidelines.
Use following project name:  apollo-eks-mock-yourname.

You can deploy the infra in your own account or in the 'be-sentia-internal-sandbox' account.
The domain name registration and Route53 hosted zone are in the internal sandbox account.

The static company website should be accessible using both www.simplyapollo.com and the apex of the domain (simplyapollo.com). Keep following requirements in mind:

    bucket encryption required
    only HTTPS traffic is allowed (forward HTTP → HTTPS)
    bucket cannot be public (use OAI)
    certificates should be managed and auto-renewed by AWS ACM


The CRM application run in an auto-scaling group. It should be accessible over crm.simplyapollo.com. This application should also be served using the same CloudFront distribution as the company website.
The custom origin should point to the ALB. SSL offloading should be handled by CloudFront. Keep following in mind:

    the solution should be high available (2 AZ's)
    use t4.small instances for the nodes
    region: eu-west-1 or eu-central-1
    VPC CIDR: 192.168.0.0/23
        public subnets: 192.168.0.0/28, 192.168.0.32/28
        private subnets: 192.168.0.64/28, 192.168.0.96/28

Deploy the autodoc and automonitoring modules.
Use apollo-yourname as prefix for the autodoc website URL.
Like
Be the first to like this
## 1.0 Set up the lab environment

Install WSL (ubuntu 22.04)
Install vscode baremetal
You want to use the zsh as default in the VScode, so that you won't open the default PS terminal.

--> https://stackoverflow.com/questions/44435697/vscode-change-default-terminal

1. Zshell installeren met config file 
    path conf file = code ~/.zshrc 
    [zsh conf file ](/apollo-asg-mock-guillaume/personal-documentation/conf-files/zshrc.bash)

```console
    # If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export PATH=$PATH:/Users/jasperbleyaert/bin
export PATH="/Users/jasperbleyaert/Library/Python/3.9/bin:$PATH"

zsh_terraform() {
  # break if there is no .terraform directory
  if [[ -d .terraform ]]; then
    local tf_workspace=$(/usr/local/bin/terraform workspace show)
    echo -n "$tf_workspace"
  fi
}
zsh_locksmith() {
    echo -n "$AWS_SESSION_ACCOUNT_NAME"
}
# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="spaceship"

load-tfswitch() {
  local tfswitchrc_path=".tfswitchrc"

  if [ -f "$tfswitchrc_path" ]; then
    tfswitch
  fi
}
add-zsh-hook chpwd load-tfswitch
load-tfswitch


# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git terraform)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

## ALIASES

alias zsh="code ~/.zshrc"

alias tfi='terraform init'

alias tfp='terraform plan' 

alias tfp='terraform apply' 

alias gcm='git checkout master; git pull'

alias gp='git pull'

alias gcb='git checkout -b'

alias ga='git add'

alias unv='unset AWS_VAULT'

alias awv='aws-vault exec'

## FUNCTIONS

function gc {
  git commit -m"$1"
}

function tfmoe {
  echo -e "\nOutputs:"
  grep -r "output \".*\"" $1 |awk '{print "\t",$2}' |tr -d '"'
  echo -e "\nVariables:"
  grep -r "variable \".*\"" $1 |awk '{print "\t",$2}' |tr -d '"'
}

function tfmoi {
  touch $1/variables.tf
  touch $1/outputs.tf
  touch $1/main.tf
}

function tfws(){
  NEW_WORKSPACE=${1%.*}
  terraform workspace select $NEW_WORKSPACE
}

function tf(){
  ACTION=$1
  WORKSPACE=${2%.*}
  VAR_FILE=$2

  echo "Action: $ACTION"
  echo "VAR_FILE: $VAR_FILE"
  echo "Workspace: $WORKSPACE"

  if [ "$2" == "" ] ; then
    terraform ${ACTION}
    return 
  fi

  if [[ -f .terraform/environment ]]; then
    if [[ "$(cat .terraform/environment)" != "${WORKSPACE}" ]] ; then
      tfws ${WORKSPACE}
    fi
  else
    tfws ${WORKSPACE}
  fi

  if [[ -f ${VAR_FILE} ]] ; then
    terraform ${ACTION} -var-file=${VAR_FILE} ${@:3}
  else
    stat ${VAR_FILE}
    echo "${VAR_FILE} does not exist!"
    terraform ${ACTION} ${@:3}
  fi
}

```

2. Terraformswitch (tfswitch)
installs the latest version of terraform and provides you with the command tfswitch , which will be helpfull for interacting with different terraform versions in different projects.
 [tfswitch site url](https://tfswitch.warrensbox.com/Install/)      

 ```console
    $ curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash
    + link aan path (PS: WSL baybeee)
```
3. AWS VAULT Install
    
    
 ```console
    code ~/.aws/config

        [default]
    # If you use a custom profile and not "default", this mfa_serial will most likely be under your own profile name!
    mfa_serial = arn:aws:iam::977812105359:mfa/filip.van.houtryve@be.sentia.com   # This is only necessary because we still have accounts using locksmith. You can remove this line if there is no locksmith left
    region     = eu-central-1   # default region -- respected by aws sso profiles and regular profiles
    format     = json           # default format -- respected by aws sso profiles and regular profiles
 
# Example of a profile still using locksmith
 
[profile diekeure-accept]
  source_profile  = default
  region          = eu-west-1
  role_arn        = arn:aws:iam::860435703519:role/filip.van.houtryve@be.sentia.com
  include_profile = <MY_PROFILE_NAME>  # this is only necessary if you don't use [default] !
 
# Example of an account that uses SSO
[profile sandbox]
  sso_start_url  = https://sentia.awsapps.com/start
  sso_region     = eu-west-1                        # <--- Region where SSO is located -- this will always be eu-west-1 in our case ( I assume )
  sso_account_id = 264601019689                     # <--- Account ID of the AWS account you're connecting to
  sso_role_name  = AWSAdministratorAccess           # <--- Name of the role you're assuming in the account. This is always the same one across accounts
  region         = eu-west-1                        # <--- Region you want to be active when connecting to the account ( both CLI as web console ). Convenient for customers that are only active in Singapore or Frankfurt instead of Ireland for example
  format         = json          

#Guillaumeconfig files 30/03         
[profile internalsandbox]
  sso_start_url  = https://sentia.awsapps.com/start
  sso_region     = eu-west-1                        
  sso_account_id = 570752136874                    
  sso_role_name  = AWSAdministratorAccess          
  region         = eu-central-1                        
  format         = json                            
  
  [profile aetn]
  sso_start_url  = https://sentia.awsapps.com/start
  sso_region     = eu-west-1                        
  sso_account_id = 521811699963                  
  sso_role_name  = AWSAdministratorAccess          
  region         = eu-west-1                        
  format         = json     %          

```
The [AWS-Vault guide](https://kerneltalks.com/tools/securing-aws-credentials-in-wsl-using-aws-vault/) I used to setup my WSL with the credentials.

Handy [Sentia Guide](https://wiki.sentia.cloud/display/SEAWSLZ/LZ+Terraform+-+Visual+Studio+Code+and+Git+Settings) for being in sync with the teams setup



4. Git configureren & Gitlab SSH adden (ssh-keygen)

SSH keys generaten + linken in sentia/accenture gitlab account.

```console
    git config --global --list
    git config --global user.name "your_username"
    git config --global user.email "your_email_address@example.com"
```


[WSL-22.04 issue](https://askubuntu.com/questions/1379425/system-has-not-been-booted-with-systemd-as-init-system-pid-1-cant-operate)

## MOCKTEST-Simplyapollo-ASG

### 1. Repository in Gitlab setup
We use gitlab repo = repo_generator 

``` console
git clone git@gitlab.infra.be.sentia.cloud:aws/landing-zones/terraform/infrastructure/repo_generator.git

```

below /config een main.yml file aanmaken  en specfiieren met project gegevens 
Edit the main.yml file under /config and specify project info.

### 2. Set up workspace
It is important to work in a clear workspace.
example workspace

```console
  Apollo(dir)
    -stacks(dir)
      -infrastructure(dir)
      -skeleton(dir)
      -global_variables.tf
```


### 3. INIT stack
This is your first stack of many to come! (Init stack)
Make a subdirectory called "init" in skeleton with 4 files.
main.tf outputs.tf production.tfvars variables.tf and link the global_variables.tf aswell use cmd below

```console
ln -s ../../global_variables.tf global_variables.tf
```

The aws_init module initialises the project in Gitlab.

```console
git@gitlab.infra.be.sentia.cloud:/aws/landing-zones/terraform/modules/aws_init?ref=v1.1.1.4
```
After cloning module in VS-code you will have to fill in the variables (global variables and local stack variables) look at apollo mocktest for the nescessary requirements. 
--> Dont forget to put the terraform remote state S3 bucket in brackets! See code below for reference

```console
# terraform {
#   backend "s3" {
#     bucket         = "tf-apollo-guillaume-eu-central-1"
#     dynamodb_table = "tf-apollo-guillaume-eu-central-1"
#     key            = "stacks/init"
#     region         = "eu-central-1"
#     role_arn       = "arn:aws:iam::570752136874:role/cross_account_sharing_role"
#   }
# }
```

```console
Terraform init (-to load the module)
Terraform plan -var=files="production.tvars" --> terraform apply -var=files="production.tvars"
```
This will apply all the resources and roles locally 
Now you will have to unbracket the "terraform backend s3"


```console
terraform {
  backend "s3" {
    bucket         = "tf-apollo-guillaume-eu-central-1"
    dynamodb_table = "tf-apollo-guillaume-eu-central-1"
    key            = "stacks/init"
    region         = "eu-central-1"
    role_arn       = "arn:aws:iam::570752136874:role/cross_account_sharing_role"
  }
}
```
Unbracket the terraform block and apply the changes linked to the bucket!
```console
Terraform apply -var=files="production.tvars"
```

The first stack of the ASG project is done! You can push it to the git branch of your desire

```console
  git checkout "branchname"
  git add .
  git commit -m "message"
  git push
  --> get the link and send it to a collegue for merge request en feedback
```

### 4. VPC stack

Same work method as the init stack.
Have a workspace ready to go!
Don't forget to apply in the correct terraform workspace! In short there are 3 possible workspaces!
1. shared service  
2. production
3. acceptance

Since we are setting up a mocktest we will only use production.tfvars files which include the production workspace!
Make sure you deploy the terraform resources in the correct workspace! check with following commands

```console
Terraform workspace list
terraform workspace new production
terraform workspace select production
```

If you are not sure that you have deployed in the correct workspace! check the state file where the resources are saved

```console
terraform state list
```
Copy the files from the init stack to your new VPC stack for best practice
You will have to use the same terraform backend s3 bucket where you will link the  local changes. Do not forget to change the key values in the backend! The value of key = directory of stack. In this case it's stacks/vpc.
Don't forget to link the global_variables.tf to EVERY new stack you make, since this is not done automatically!


There are different ways to setup terraform resources. 
In the beginning you might want to look at the resources individually and create the infrastructure and underlying attachments step by step. This consumes some of your time but will be rewarding in the long run. [Reading terraform registry](https://registry.terraform.io/) and the possible options of resources is a good start.
You have to realise that modules are an impactfull feature in Terraform and allows you to copy a default working infrastructure stack when you change the variables correctly. 

There you can find an example usage of the VPC Module! Use [apollo-mock](https://gitlab.infra.be.sentia.cloud/aws/be/projects/apollo-asg-mock-guillaume) on gitlab as an example!
 ```console
 git@gitlab.infra.be.sentia.cloud:provisioning/terraform/aws/modules/aws_vpc.git?ref=v2.0.0.0
 ```

Currently we are using NETBOX as a cidr provider. 
If you have access to netbox you can claim or create your own unused cidr block. 
This is important to know which cidr block you can use for the test and how you will seperate your subnets! (Ask help from collegues)

For the Apollo ASG mocktest a seperation into private and public subnets is enough. 
For the EKS- mocktest you will have to use a EKS-Subnet / private / public subnet seperation.
The VPC is part of the skeleton folder and is very important for the rest of your infrastructure. Choose your subnets wisely!

 
 [RECAP OF CODE-VPC ](RECAP/vpc/main.tf) - more in detail

Check the output in the AWSCLI!

### 5. ROUTE53 

Route53 stack as subdirectory in skeleton. In my case the hosted zone domain "simplyapollo.com" was already registered. 
This means that terraform wasn't used to create the resource and it won't be in the tfstate file! 

Terraform import or Data block. 
Data sources allow Terraform to use information defined outside of Terraform, defined by another separate Terraform configuration, or modified by functions.
Terraform import means you are going to import existing infrastructure like a hosted zone and link it to a resource. From now on you have to manage it with the terraform stack.

I used [Terraform Import](https://developer.hashicorp.com/terraform/cli/import) in this stack but it is not nescessary. 
In the ACM stack (the following topic) I've used a data block research to get the HOSTED_ZONE_ID which is probably faster and more common.

```console
  $ terraform import aws_route53_zone.myzone zone.id
````
Since
6. ACM (aws certificate manager)

According to the mockexercise the certificiate will be managed by cloudfront.
In the MAIN.TF file you'll find the resources nescessary to create a certificate in a specified region, the linked DNS validated certificate and the record.

It is important to understand that you'll have to create 2 websites. 

1. crm.simplyapollo.com  
2. www.simplyapollo.com

The first website is a static website hosted on an S3 bucket!

DNS records in Route53
www.simplyapollo.com==  CNAME --> simplyapollo.com == Alias (A-record) --> Cloudfront distribution
ACM's linked to cloudfront have to be deployed in the N.Virgina region, since cloudfront works Global. 

### 6. S3 

S3 is the first stack in directory infrastructure.
This has to be a s3 bucket filled with static website pages. You can find them [here](https://gitlab.infra.be.sentia.cloud/aws/be/projects/aws-mock-exercise)

You can create the bucket in a way of your choosing. I've chosen for the module "aws_s3_mybucket" which you can find [here](https://gitlab.infra.be.sentia.cloud/aws/landing-zones/terraform/modules/aws_s3/aws_s3_bucket)

You can manually add the site files or use s3 objects as in the example.

The bucket needs a policy to allow the cloudfront to access the files.

Conform the nescessities the bucket needs a private acl config.

In the same stack the cloudfront origin access control is created and linked to a cloudfront distribution!
The cloudfront distribution gets the Viewer_certificate you made in the ACM stack

You can use [apollo project](https://gitlab.infra.be.sentia.cloud/aws/be/projects/apollo-asg-mock-guillaume)



### 7. EC2

The 2nd stack in the infrastructure directory.
Here we will set up the 2nd website --> crm.simplyapollo.com

You will have to make a connection in this stack with the VPC stack since you will create an Autoscaling group (ASG) behind a load balancer. 
Figure out how to use a data terraform_remote_state.vpc block to link the vpc stack. Remark the output.tf file in the VPC stack!

Create an ASG and a launch template (use the correct instance_type).
Create an ALB that balances the load on the EC2 instances.
Create a Target Group that is attached to the ALB and the ASG.
Keep in mind the security groups and minimalise the inbound/outbound traffic.
Create a Cloudfront distribution linked to an ALB origin.

Check the setup!
If everything went right you have now successfully set up the Apollo-ASG-Mocktest.


### 8. EKS

The second mocktest currently can be fount [here](https://wiki.sentia.cloud/display/SEAWSLZ/BE+AWS+Mock+Exercise+-+EKS+version).
The infrastructue to support the crm.simplyapollo application differentiates from the first one. We will not use an ASG and EC2 but we will use EKS which is amazon way of suppot K8s. This is a bit more complicated since it is a different approach. If you want to set up the entire mocktest you can setup the static website on the s3 bucket with the info above. 

From this point we will focus on setting up the crm.simplyapollo.com from scratch using EKS 
You'll have to use gain some basic understanding of the tools used to set up a cluster in EKS.
Some sites that came in handy are [amazon doc](https://repost.aws/knowledge-center/eks-access-kubernetes-services) , [EKS-blog](https://rajesh007.medium.com/kubernetes-ingress-on-eks-aws-9abcad9f4be7) , [K8s official doc](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

You will have to install and use the kubectl tool to manage the cluster, namespaces, deployments, service and pods.

[Installation guide](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) for kubectl

The team uses k9s and it is a GUI which can come in handy to check the logs of your pods
Linux debian ubuntu22.04 doesn't have brew automatically installed. You can use [this guide](https://linux.how2shout.com/install-brew-on-ubuntu-22-04-lts-jammy-linux/) to install LinuxBrew

```console
   brew install derailed/k9s/k9s
```
Make a stack EKS in infrastructure directory. 
Make sure you have setup your workspace correctly. Check guide above to use the best practices.
Start with creating our cluster! Use the modules specified in Gitlab they can be a great starting point.
As mentioned above you'll need the VPC and the 3 subnets specified to be reachable in your new EKS stack. 

The EKS module is a bit tricky. Take some time reading all the possibilities. If you fill in the variables and read the module you realise that it creates a complete EKS cluster with all needed dependencies such as:

1. An autoscaling group for the workers
2. IAM roles / IAM policies / Assume roles that allow EKS to access the autoscaling group and visa versa

You will need some plugins to help simplify the deployment.  
You can find the modules below.


#### [EKS](https://gitlab.infra.be.sentia.cloud/aws/landing-zones/terraform/modules/aws_eks)
-> Creates EKS cluster met OIDC ASG workgroup. In my case 3xm5.large 

#### [ALB-Controller](https://gitlab.infra.be.sentia.cloud/aws/landing-zones/terraform/modules/eks_plugins/aws_load_balancer_controller/-/blob/master/docs/project_info.md)
-> You will need this after creating the ingress. Deploying this plugin (aws_lb_controller) will make sure ALB is provisioned that load balances all incomming traffic when an ingress is deployed.
Use [ALB on AWS EKS](https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html) as source. 
When using the controller make sure you add the tagg to the public subnets. So k8s can use the right subnets for the external loadbalancers.

#### [vpc_cni](https://gitlab.infra.be.sentia.cloud/aws/landing-zones/terraform/modules/eks_plugins/vpc_cni)

The Amazon VPC CNI plugin for Kubernetes add-on is deployed on each Amazon EC2 node in your Amazon EKS cluster. The add-on creates elastic network interfaces and attaches them to your Amazon EC2 nodes. The add-on also assigns a private IPv4 or IPv6 address from your VPC to each pod and service.
Other compatible CNI plugins are available for use on Amazon EKS clusters, but this is the only CNI plugin supported by Amazon EKS.

#### [core_dns](https://gitlab.infra.be.sentia.cloud/aws/landing-zones/terraform/modules/eks_plugins)

CoreDNS is a flexible, extensible DNS server that can serve as the Kubernetes cluster DNS. When you launch an Amazon EKS cluster with at least one node, two replicas of the CoreDNS image are deployed by default, regardless of the number of nodes deployed in your cluster. The CoreDNS pods provide name resolution for all pods in the cluster. 

#### [Kube-proxy](https://gitlab.infra.be.sentia.cloud/aws/landing-zones/terraform/modules/eks_plugins)

The Kubernetes network proxy runs on each node. This reflects services as defined in the Kubernetes API on each node and can do simple TCP, UDP, and SCTP stream forwarding or round robin TCP, UDP, and SCTP forwarding across a set of backends.


#### [cluster_autoscaler](https://gitlab.infra.be.sentia.cloud/aws/landing-zones/terraform/modules/eks_plugins) 
manages the scaling of the nodes. No nodes will be unused and will automatically scale if nescessary.

Configure Kubectl so you can connect to your AWS EKS Cluster

```console
 aws eks update-kubeconfig --region eu-central-1 --name eks-cluster-apollo
```
Now you can start using kubectl or k9s!
- Create a deployment with the replicaset
- Create a service 
- Create an ingress with the right alb annotations.
- Verify the targetgroup and ports in awscli

### 9. ECR

While creating the deployment you'll have to pull a container image.
Feel free to make a docker file, which you can use to build a docker image and push it to the ECR.

 

























<!-- 
```markdown
![alt text](path/to/image.jpg)
``` -->