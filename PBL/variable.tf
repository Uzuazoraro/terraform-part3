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
      default = 2
}
