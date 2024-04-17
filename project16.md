## AUTOMATE INFRASTRUCTURE WITH IAC USING TERRAFORM PART 1
   ==================================================================

![set-up](image-1.png)

Prerequisites before you begin writing Terraform code
•	You must have completed Terraform course from the Learning dashboard
•	Create an IAM user, name it terraform (ensure that the user has only programatic access to your AWS account) and grant this user AdministratorAccess permissions.

Steps:
Create AWS Organization > Create User > Set permission > Grant access by clicking aws account, select mgt acct and assign users or groups > click user and select the user > next.......

Create user
============

Click IAM > user and give it a name > click on user group to create a user group > give administrative access and attach the policy > create user > click on the created user name > click security credentials > click create access key.

•	Copy the secret access key and access key ID. Save them in a notepad temporarily.
•	Configure programmatic access from your workstation to connect to AWS using the access keys (type: $ "aws configure" on your terminal) copied above and a Python SDK (boto3). You must have Python 3.6 or higher on your workstation.
If you are on Windows, use gitbash, if you are on a Mac, you can simply open a terminal. Read here to configure the Python SDK properly.
For easier authentication configuration – use AWS CLI with aws configure command.

## Make sure boto3 is installed
## Create this file file: 'test.py' and paste:

import boto3
s3 = boto3.resource('s3')
for bucket in s3.buckets.all():
    print(bucket.name)

Type 'py test.py' and the name of the bucket you created will come up.  

•	Create an S3 bucket (https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html) to store Terraform state file. You can name it something like <yourname>-dev-terraform-bucket (Note: S3 bucket names must be unique unique within a region partition, you can read about S3 bucket naming in this article "https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html").

## VPC | SUBNETS | SECURITY GROUPS
========================================================================

## Create a folder called PBL Create a file in the folder, name it main.tf

Provider and VPC resource section
Set up Terraform CLI as per this instruction.

Add AWS as a provider, and a resource to create a VPC in the main.tf file. Provider block informs Terraform that we intend to build infrastructure within AWS. Resource block will create a VPC. provider "aws" { region = "us-east-2" }

provider "aws" {
  region = "us-east-2"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block                     = "172.16.0.0/16"
  enable_dns_support             = "true"
  enable_dns_hostnames           = "true"
  enable_classiclink             = "false"
  enable_classiclink_dns_support = "false"
}

Note: You can change the configuration above to create your VPC in other region that is closer to you. The same applies to all configuration snippets that will follow.
•	The next thing we need to do, is to download necessary plugins for Terraform to work. These plugins are used by providers and provisioners. At this stage, we only have provider in our main.tf file. So, Terraform will just download plugin for AWS provider.
•	Lets accomplish this with terraform init command as seen in the below demonstration.
+ Run 'terraform plan'
+ Run 'terraform apply'

Observations:
1.	A new file is created terraform.tfstate This is how Terraform keeps itself up to date with the exact state of the infrastructure. It reads this file to know what already exists, what should be added, or destroyed based on the entire terraform code that is being developed.
2.	If you also observed closely, you would realize that another file gets created during planning and apply. But this file gets deleted immediately. terraform.tfstate.lock.info This is what Terraform uses to track, who is running its code against the infrastructure at any point in time. This is very important for teams working on the same Terraform repository at the same time. The lock prevents a user from executing Terraform configuration against the same infrastructure when another user is doing the same – it allows to avoid duplicates and conflicts.

## Provider and VPC resource section
===================================================

## Set up Terraform CLI as per this instruction (https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

The secrets of writing quality Terraform code
The secret recipe of a successful Terraform projects consists of:
•	Your understanding of your goal (desired AWS infrastructure end state)
•	Your knowledge of the IaC technology used (in this case – Terraform)
•	Your ability to effectively use up to date Terraform documentation here
As you go along completing this project, you will get familiar with Terraform-specific terminology, such as:
•	Attribute
•	Resource
•	Interpolations
•	Argument
•	Providers
•	Provisioners
•	Input Variables
•	Output Variables
•	Module
•	Data Source
•	Local Values
•	Backend
Make sure you understand them and know when to use each of them.

## Best practices
==============================

•	Ensure that every resource is tagged using multiple key-value pairs. You will see this in action as we go along.
•	Try to write reusable code, avoid hard coding values wherever possible. (For learning purpose, we will start by hard coding, but gradually refactor our work to follow best practices).
VPC | SUBNETS | SECURITY GROUPS
VPC | Subnets | Security Groups

## Subnets resource section
===============================

According to our architectural design, we require 6 subnets:
•	2 public
•	2 private for webservers
•	2 private for data layer
Let us create the first 2 public subnets.
Add below configuration to the main.tf file:

## Create public subnets1
    resource "aws_subnet" "public1" {
    vpc_id                     = aws_vpc.main.id
    cidr_block                 = "172.16.0.0/24"
    map_public_ip_on_launch    = true
    availability_zone          = "us-east-2a"
}

# Create public subnet2
    resource "aws_subnet" "public2" {
    vpc_id                     = aws_vpc.main.id
    cidr_block                 = "172.16.1.0/24"
    map_public_ip_on_launch    = true
    availability_zone          = "us-east-2b"
}

## Fixing The Problems By Code Refactoring
============================================
•	Fixing Hard Coded Values: We will introduce variables, and remove hard coding.
  +	Starting with the provider block, declare a variable named region, give it a default value, and update   the provider section by referring to the declared variable.
•	 
   variable "region" {
•	        default = "us-east-2"
•	    }
•	
•	    provider "aws" {
•	        region = var.region
•	    }

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

provider "aws" {
region = var.region
}

# Create VPC
resource "aws_vpc" "main" {
cidr_block                     = var.vpc_cidr
enable_dns_support             = var.enable_dns_support 
enable_dns_hostnames           = var.enable_dns_support
enable_classiclink             = var.enable_classiclink
enable_classiclink_dns_support = var.enable_classiclink

}

## Fixing multiple resource blocks: 
===========================================
This is where things become a little tricky. It’s not complex, we are just going to introduce some interesting concepts. Loops & Data sources
Terraform has a functionality that allows us to pull data which exposes information to us. For example, every region has Availability Zones (AZ). Different regions have from 2 to 4 Availability Zones. With over 20 geographic regions and over 70 AZs served by AWS, it is impossible to keep up with the latest information by hard coding the names of AZs. Hence, we will explore the use of Terraform’s Data Sources to fetch information outside of Terraform. In this case, from AWS
Let us fetch Availability zones from AWS, and replace the hard coded value in the subnet’s availability_zone section.
Let’s make cidr_block dynamic. We will introduce a function cidrsubnet() to make this happen. It accepts 3 parameters. Let us use it first by updating the configuration, then we will explore its internals.

## Let us fetch Availability zones from AWS, and replace the hard coded value in the subnet’s availability_zone section.

## Get list of availability zones

        data "aws_availability_zones" "available" {
        state = "available"
        }

To make use of this new data resource, we will need to introduce a count argument in the subnet block: Something like this.
    # Create public subnet1
    resource "aws_subnet" "public" { 
        count                   = 2
        vpc_id                  = aws_vpc.main.id
        cidr_block              = "172.16.1.0/24"
        map_public_ip_on_launch = true
        availability_zone       = data.aws_availability_zones.available.names[count.index]

    }
Let us quickly understand what is going on here.
•	The count tells us that we need 2 subnets. Therefore, Terraform will invoke a loop to create 2 subnets.
•	The data resource will return a list object that contains a list of AZs. Internally, Terraform will receive the data like this
  ["us-east-2a", "us-east-b"]

 Each of them is an index, the first one is index 0, while the other is index 1. If the data returned had more than 2 records, then the index numbers would continue to increase.

 Therefore, each time Terraform goes into a loop to create a subnet, it must be created in the retrieved AZ from the list. Each loop will need the index number to determine what AZ the subnet will be created. That is why we have data.aws_availability_zones.available.names[count.index] as the value for availability_zone. When the first loop runs, the first index will be 0, therefore the AZ will be us-east-2a. The pattern will repeat for the second loop.
But we still have a problem. If we run Terraform with this configuration, it may succeed for the first time, but by the time it goes into the second loop, it will fail because we still have cidr_block hard coded. The same cidr_block cannot be created twice within the same VPC. So, we have a little more work to do.
Let’s make cidr_block dynamic.

+ Update the configuration:

# Create public subnet1
    resource "aws_subnet" "public" { 
        count                   = 2
        vpc_id                  = aws_vpc.main.id
        cidr_block              = cidrsubnet(var.vpc_cidr, 4 , count.index)
        map_public_ip_on_launch = true
        availability_zone       = data.aws_availability_zones.available.names[count.index]

    }

Its parameters are cidrsubnet(prefix, newbits, netnum)
•	The prefix parameter must be given in CIDR notation, same as for VPC.
•	The newbits parameter is the number of additional bits with which to extend the prefix. For example, if given a prefix ending with /16 and a newbits value of 4, the resulting subnet address will have length /20
•	The netnum parameter is a whole number that can be represented as a binary integer with no more than newbits binary digits, which will be used to populate the additional bits added to the prefix
You can experiment how this works by entering the terraform console and keep changing the figures to see the output.
•	On the terminal, run terraform console
•	type cidrsubnet("172.16.0.0/16", 4, 0)
•	Hit enter
•	See the output
•	Keep changing the numbers and see what happens.
•	To get out of the console, type exit

+ The final problem to solve is removing hard coded count value.

To do this, we can introuduce length() function, which basically determines the length of a given list, map, or string.
Since data.aws_availability_zones.available.names returns a list like ["eu-central-1a", "eu-central-1b", "eu-central-1c"] we can pass it into a lenght function and get number of the AZs.
length(["us-east-2a", "us-east-2b", "us-east-2c"])
Open up terraform console and try it

Now we can simply update the public subnet block like this
# Create public subnet1
    resource "aws_subnet" "public" { 
        count                   = length(data.aws_availability_zones.available.names)
        vpc_id                  = aws_vpc.main.id
        cidr_block              = cidrsubnet(var.vpc_cidr, 4 , count.index)
        map_public_ip_on_launch = true
        availability_zone       = data.aws_availability_zones.available.names[count.index]

    }

Observations:
•	What we have now, is sufficient to create the subnet resource required. But if you observe, it is not satisfying our business requirement of just 2 subnets. The length function will return number 3 to the count argument, but what we actually need is 2.
Now, let us fix this.
•	Declare a variable to store the desired number of public subnets, and set the default value
•	variable "preferred_number_of_public_subnets" {
•	  default = 2
}
•	Next, update the count argument with a condition. Terraform needs to check first if there is a desired number of subnets. Otherwise, use the data returned by the lenght function. See how that is presented below.
# Create public subnets
resource "aws_subnet" "public" {
  count  = var.preferred_number_of_public_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_public_subnets   
  vpc_id = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4 , count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

}

Now lets break it down:
•	The first part var.preferred_number_of_public_subnets == null checks if the value of the variable is set to null or has some value defined.
•	The second part ? and length(data.aws_availability_zones.available.names) means, if the first part is true, then use this. In other words, if preferred number of public subnets is null (Or not known) then set the value to the data returned by lenght function.
•	The third part : and var.preferred_number_of_public_subnets means, if the first condition is false, i.e preferred number of public subnets is not null then set the value to whatever is definied in var.preferred_number_of_public_subnets

Now the entire configuration should now look like this
# Get list of availability zones
data "aws_availability_zones" "available" {
state = "available"
}

variable "region" {
      default = "eu-central-1"
}

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

provider "aws" {
  region = var.region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block                     = var.vpc_cidr
  enable_dns_support             = var.enable_dns_support 
  enable_dns_hostnames           = var.enable_dns_support
  enable_classiclink             = var.enable_classiclink
  enable_classiclink_dns_support = var.enable_classiclink

}

# Create public subnets
resource "aws_subnet" "public" {
  count  = var.preferred_number_of_public_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_public_subnets   
  vpc_id = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4 , count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

}
Note: You should try changing the value of preferred_number_of_public_subnets variable to null and notice how many subnets get created.


+ INTRODUCING VARIABLES.TF & TERRAFORM.TFVARS
===============================================

Instead of having a long list of variables in main.tf file, we can actually make our code a lot more readable and better structured by moving out some parts of the configuration content to other files.
•	We will put all variable declarations in a separate file
•	And provide non default values to each of them
1.	Create a new file and name it variables.tf
2.	Copy all the variable declarations into the new file.
3.	Create another file, name it terraform.tfvars
4.	Set values for each of the variables.

Maint.tf
# Get list of availability zones
data "aws_availability_zones" "available" {
state = "available"
}

provider "aws" {
  region = var.region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block                     = var.vpc_cidr
  enable_dns_support             = var.enable_dns_support 
  enable_dns_hostnames           = var.enable_dns_support
  enable_classiclink             = var.enable_classiclink
  enable_classiclink_dns_support = var.enable_classiclink

}

# Create public subnets
resource "aws_subnet" "public" {
  count  = var.preferred_number_of_public_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_public_subnets   
  vpc_id = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4 , count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
}
variables.tf
variable "region" {
      default = "eu-central-1"
}

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
      default = null
}
terraform.tfvars
region = "eu-central-1"

vpc_cidr = "172.16.0.0/16" 

enable_dns_support = "true" 

enable_dns_hostnames = "true"  

enable_classiclink = "false" 

enable_classiclink_dns_support = "false" 

preferred_number_of_public_subnets = 2
You should also have this file structure in the PBL folder.
└── PBL
    ├── main.tf
    ├── terraform.tfstate
    ├── terraform.tfstate.backup
    ├── terraform.tfvars
    └── variables.tf
Run terraform plan and ensure everything works



# PROJECT 17 - TERRAFORM PART 2
===========================================

## Continue Infrastructure Automation with Terraform

Let us continue from where we have stopped in Project 16.
Based on the knowledge from the previous project lets keep on creating AWS resources!

## Networking

Private subnets & best practices

## Create 4 private subnets keeping in mind following principles:

•	Make sure you use variables or length() function to determine the number of AZs
•	Use variables and cidrsubnet() function to allocate vpc_cidr for subnets
•	Keep variables and resources in separate files for better code structure and readability
•	Tags all the resources you have created so far. Explore how to use format() and count functions to automatically tag subnets with its respective number.

# Create private subnets
resource "aws_subnet" "private" {
  count  = var.preferred_number_of_private_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_private_subnets   
  vpc_id = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8 , count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
}