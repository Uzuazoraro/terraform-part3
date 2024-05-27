variable "region" {
     default = "us-east-2"
 }

# Do the same to cidr value in the vpc block, and all the other arguments.
 variable "vpc_cidr" {
      default = "172.16.0.0/16"
 }
 variable "enable_dns_support" {
      default = "true"
 }
 variable "enable_dns_hostnames" {
      default ="true" 
 }
 variable "enable_classiclink" {
      default = "false"
 }
 variable "enable_classiclink_dns_support" {
      default = "false"
 }
variable "preferred_number_of_public_subnets" {
      type = number
      description = "number of public subnets"
}
variable "preferred_number_of_private_subnets" {
     type = number
     description = "number of private subnets"
}

variable "name" {
     type = string
     default = "Micolo"
}

variable "tags" {
  description = "A mapping of tags to assign to all resources."
  type        = map(string)
  default     = {}
}

variable "environment" {
  type        = string
  description = "the type of enviroment"
}

variable "ami" {
  type        = string
  description = "AMI ID for the launch template"
}

variable "keypair" {
  type        = string
  description = "key pair for the instances"
}

variable "account_no" {
  type        = number
  description = "the account number"
}
