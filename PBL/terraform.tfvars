region = "us-east-2"

vpc_cidr = "172.16.0.0/16"

enable_dns_support = "true"

# enable_dns_hostnames = "true"

# enable_classiclink = "false"

# enable_classiclink_dns_support = "false"

preferred_number_of_public_subnets = 2

preferred_number_of_private_subnets = 4

environment = "production"

# Ensure to change this to your acccount number
account_no = "421000527042"
tags = {
  Enviroment      = "production" 
  Owner-Email     = "micaho2k@gmail.com"
  Managed-By      = "Terraform"
  Billing-Account = "421000527042"
}

ami = "ami-ami-09040d770ffe2224f"

keypair = "devops"

