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

A little bit more about Tagging
Tagging is a straightforward, but a very powerful concept that helps you manage your resources much more efficiently:
•	Resources are much better organized in ‘virtual’ groups
•	They can be easily filtered and searched from console or programmatically
•	Billing team can easily generate reports and determine how much each part of infrastructure costs how much (by department, by type, by environment, etc.)
•	You can easily determine resources that are not being used and take actions accordingly
•	If there are different teams in the organization using the same account, tagging can help differentiate who owns which resources.
Note: You can add multiple tags as a default set. for example, in out terraform.tfvars file we can have default tags defined.
tags = {
  Enviroment      = "production" 
  Owner-Email     = "dare@darey.io"
  Managed-By      = "Terraform"
  Billing-Account = "1234567890"
}

## Now you can tag all your resources using the format below

tags = merge(
    var.tags,
    {
      Name = "Name of the resource"
    },
  )

## NOTE: Update the variables.tf to declare the variable tags used in the format above;

variable "tags" {
  description = "A mapping of tags to assign to all resources."
  type        = map(string)
  default     = {}
}

The nice thing about this is – anytime we need to make a change to the tags, we simply do that in one single place (terraform.tfvars).
But, our key-value pairs are hard coded. So, go ahead and work out a fix for that. Simply create variables for each value and use var.variable_name as the value to each of the keys.
Apply the same best practices for all other resources you will create further.
Internet Gateways & format() function
Create an Internet Gateway in a separate Terraform file internet_gateway.tf
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = format("%s-%s!", aws_vpc.main.id,"IG")
    } 
  )
}
Did you notice how we have used format() function to dynamically generate a unique name for this resource? The first part of the %s takes the interpolated value of aws_vpc.main.id while the second %s appends a literal string IG and finally an exclamation mark is added in the end.
If any of the resources being created is either using the count function, or creating multiple resources using a loop, then a key-value pair that needs to be unique must be handled differently.
For example, each of our subnets should have a unique name in the tag section. Without the format() function, we would not be able to see uniqueness. With the format function, each private subnet’s tag will look like this.
Name = PrvateSubnet-0
Name = PrvateSubnet-1
Name = PrvateSubnet-2
Lets try and see that in action.
  tags = merge(
    var.tags,
    {
      Name = format("PrivateSubnet-%s", count.index)
    } 
  )

##NAT Gateways
===============================

Create 1 NAT Gateways and 1 Elastic IP (EIP) addresses
Now use similar approach to create the NAT Gateways in a new file called natgateway.tf.
Note: We need to create an Elastic IP for the NAT Gateway, and you can see the use of depends_on to indicate that the Internet Gateway resource must be available before this should be created. Although Terraform does a good job to manage dependencies, but in some cases, it is good to be explicit.
You can read more on dependencies here (https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on)

resource "aws_eip" "nat_eip" {
  domain        = "vpc"
  depends_on = [aws_internet_gateway.ig]

  tags = merge(
    var.tags,
    {
      Name = format("%s-EIP", var.name)
    },
  )
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public.*.id, 0)
  depends_on    = [aws_internet_gateway.ig]

  tags = merge(
    var.tags,
    {
      Name = format("%s-Nat", var.name)
    },
  )
}


## AWS ROUTES
=========================

## Create a file called route_tables.tf and use it to create routes for both public and private subnets, create the below resources. Ensure they are properly tagged.
•	aws_route_table
•	aws_route
•	aws_route_table_association

## create private route table
=================================

resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = format("%s-Private-Route-Table-%s", var.name, var.environment)
    },
  )
}

# associate all private subnets to the private route table
resource "aws_route_table_association" "private-subnets-assoc" {
  count          = length(aws_subnet.private[*].id)
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private-rtb.id
}

# create route table for the public subnets
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = format("%s-Public-Route-Table-%s", var.name, var.environment)
    },
  )
}

# create route for the public route table and attach the internet gateway
resource "aws_route" "public-rtb-route" {
  route_table_id         = aws_route_table.public-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

# associate all public subnets to the public route table
resource "aws_route_table_association" "public-subnets-assoc" {
  count          = length(aws_subnet.public[*].id)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public-rtb.id
}

## Now if you run terraform plan and terraform apply it will add the following resources to AWS in multi-az set up:

•	 – Our main vpc
•	 – 2 Public subnets
•	 – 4 Private subnets
•	 – 1 Internet Gateway
•	 – 1 NAT Gateway
•	 – 1 EIP
•	 – 2 Route tables

Now, we are done with Networking part of AWS set up, let us move on to Compute and Access Control configuration automation using Terraform!

## AWS Identity and Access Management
=============================================
IaM and Roles

We want to pass an IAM role our EC2 instances to give them access to some specific resources, so we need to do the following:

1.	Create AssumeRole

Assume Role uses Security Token Service (STS) API that returns a set of temporary security credentials that you can use to access AWS resources that you might not normally have access to. These temporary credentials consist of an access key ID, a secret access key, and a security token. Typically, you use AssumeRole within your account or for cross-account access.

Add the following code to a new file named roles.tf

resource "aws_iam_role" "ec2_instance_role" {
name = "ec2_instance_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "aws assume role"
    },
  )
}


## In this code we are creating AssumeRole with AssumeRole policy. It grants to an entity, in our case it is an EC2, permissions to assume the role.

2.	Create IAM policy for this role
==============================================  

This is where we need to define a required policy (i.e., permissions) according to our requirements. For example, allowing an IAM role to perform action describe applied to EC2 instances:

resource "aws_iam_policy" "policy" {
  name        = "ec2_instance_policy"
  description = "A test policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]

  })

  tags = merge(
    var.tags,
    {
      Name =  "aws assume policy"
    },
  )

}


3.	Attach the Policy to the IAM Role
=======================================

This is where, we will be attaching the policy which we created above, to the role we created in the first step.

    resource "aws_iam_role_policy_attachment" "test-attach" {
        role       = aws_iam_role.ec2_instance_role.name
        policy_arn = aws_iam_policy.policy.arn
    }

4.	Create an Instance Profile and interpolate the IAM Role
=============================================================

    resource "aws_iam_instance_profile" "ip" {
        name = "aws_instance_profile_test"
        role =  aws_iam_role.ec2_instance_role.name
    }

## We are pretty much done with Identity and Management part for now, let us move on and create other resources required.

## Resources to be created
=============================

As per our architecture we need to do the following:
1.	Create Security Groups
2.	Create Target Group for Nginx, WordPress and Tooling
3.	Create certificate from AWS certificate manager
4.	Create an External Application Load Balancer and Internal Application Load Balancer.
5.	create launch template for Bastion, Tooling, Nginx and WordPress
6.	Create an Auto Scaling Group (ASG) for Bastion, Tooling, Nginx and WordPress
7.	Create Elastic Filesystem
8.	Create Relational Database (RDS)

## We are going to create all the security groups in a single file, then we are going to refrence this security group within each resources that needs it.

Create a file and name it security.tf
Create all the security groups inside this file.

IMPORTANT:
•	Check out the terraform documentation for security group (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
•	Check out the terraform documentation for security group rule (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)


## CREATE CERTIFICATE FROM AMAZON CERIFICATE MANAGER
Create cert.tf file and add the following code snippets to it.

## . Create an external (Internet facing) Application Load Balancer (ALB)
Create a file called alb.tf
First of all we will create the ALB, then we create the target group and lastly we will create the lsitener rule.
Useful Terraform Documentation, go through this documentation and understand the arguement needed for each resources:
•	ALB
•	ALB-target
•	ALB-listener
We need to create an ALB to balance the traffic between the Instances:

To inform our ALB to where route the traffic we need to create a Target Group to point to its targets:

Then we will need to create a Listener for this target Group

# Add the following outputs to output.tf to print them on screen

output "alb_dns_name" {
  value = aws_lb.ext-alb.dns_name
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.nginx-tgt.arn
}


# Create an Internal (Internal) Application Load Balancer (ALB)
For the Internal Load balancer we will follow the same concepts with the external load balancer.

For the Internal Load balancer we will follow the same concepts with the external load balancer.
Add the code snippets inside the alb.tf file
# ----------------------------
#Internal Load Balancers for webservers
#---------------------------------

resource "aws_lb" "ialb" {
  name     = "ialb"
  internal = true
  security_groups = [
    aws_security_group.int-alb-sg.id,
  ]

  subnets = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id
  ]

  tags = merge(
    var.tags,
    {
      Name = "Micolo-int-alb"
    },
  )

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

To inform our ALB to where route the traffic we need to create a Target Group to point to its targets:
# --- target group  for wordpress -------

resource "aws_lb_target_group" "wordpress-tgt" {
  health_check {
    interval            = 10
    path                = "/healthstatus"
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "wordpress-tgt"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
}

# --- target group for tooling -------

resource "aws_lb_target_group" "tooling-tgt" {
  health_check {
    interval            = 10
    path                = "/healthstatus"
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "tooling-tgt"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
}
Then we will need to create a Listener for this target Group
# For this aspect a single listener was created for the wordpress which is default,
# A rule was created to route traffic to tooling when the host header changes

resource "aws_lb_listener" "web-listener" {
  load_balancer_arn = aws_lb.ialb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.oyindamola.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress-tgt.arn
  }
}

# listener rule for tooling target

resource "aws_lb_listener_rule" "tooling-listener" {
  listener_arn = aws_lb_listener.web-listener.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tooling-tgt.arn
  }

  condition {
    host_header {
      values = ["tooling.zireuz.com"]
    }
  }
}

## CREATING AUTOSCALING GROUPS

This Section we will create the Auto Scaling Group (ASG) (https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html)

Now we need to configure our ASG to be able to scale the EC2s out and in depending on the application traffic.
Before we start configuring an ASG, we need to create the launch template and the the AMI needed. For now we are going to use a random AMI from AWS, then in project 19, we will use Packer to create our ami.
Based on our Architecture we need for Auto Scaling Groups for bastion, nginx, wordpress and tooling, so we will create two files; asg-bastion-nginx.tf will contain Launch Template and Autoscaling group for Bastion and Nginx, then asg-wordpress-tooling.tf will contain Launch Template and Austoscaling group for wordpress and tooling.
Useful Terraform Documentation, go through this documentation and understand the arguement needed for each resources:
•	SNS-topic
•	SNS-notification
•	Austoscaling
•	Launch-template


## Create asg-bastion-nginx.tf and paste all the code snippet below;

#### creating sns topic for all the auto scaling groups

resource "aws_sns_topic" "david-sns" {
name = "Default_CloudWatch_Alarms_Topic"
}
creating notification for all the auto scaling groups
resource "aws_autoscaling_notification" "david_notifications" {
  group_names = [
    aws_autoscaling_group.bastion-asg.name,
    aws_autoscaling_group.nginx-asg.name,
    aws_autoscaling_group.wordpress-asg.name,
    aws_autoscaling_group.tooling-asg.name,
  ]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.david-sns.arn
}

## STORAGE AND DATABASE

Useful Terraform Documentation, go through this documentation and understand the arguement needed for each resources:
•	RDS {https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group}
•	EFS {https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system}
•	KMS {https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key}

Create Elastic File System (EFS)
In order to create an EFS you need to create a KMS key.
AWS Key Management Service (KMS) makes it easy for you to create and manage cryptographic keys and control their use across a wide range of AWS services and in your applications.

Create MySQL RDS
Let us create the RDS itself using this snippet of code in rds.tf file:
# This section will create the subnet group for the RDS  instance using the private subnet
resource "aws_db_subnet_group" "ACS-rds" {
  name       = "acs-rds"
  subnet_ids = [aws_subnet.private[2].id, aws_subnet.private[3].id]

 tags = merge(
    var.tags,
    {
      Name = "ACS-rds"
    },
  )
}

# create the RDS instance with the subnets group
resource "aws_db_instance" "ACS-rds" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "daviddb"
  username               = var.master-username
  password               = var.master-password
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = aws_db_subnet_group.ACS-rds.name
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.datalayer-sg.id]
  multi_az               = "true"
}

At this point, you shall have pretty much all infrastructure elements ready to be deployed automatically, but before we plan and apply our code we need to take note of two things;
•	we have a long list of files which may looks confusing but that is not bad for a start, we are going to fix this using the concepts of modules in Project 18
•	Secondly, our application won’t work because in out shell script that was passed into the launch some endpoints like the RDs and EFS point is needed in which they have not been created yet. So, in project 19 we will use our Ansible knowledge to fix this.
Try to plan and apply your Terraform codes, explore the resources in AWS console and make sure you destroy them right away to avoid massive costs.
Additional tasks
In addition to regular project submission include following:
1.	Summarise your understanding on Networking concepts like IP Address, Subnets, CIDR Notation, IP Routing, Internet Gateways, NAT
2.	Summarise your understanding of the OSI Model, TCP/IP suite and how they are connected – research beyond the provided articles, watch different YouTube videos to fully understand the concept around OSI and how it is related to the Internet and end-to-end Web Solutions. You don not need to memorise the layers – just understand the idea around it.
3.	Explain the difference between assume role policy and role policy
Congratulations!
Now you have fully automated creation of AWS Infrastructure for 2 websites with Terraform. In the next project we will further enhance our codes by refactoring and introducing more exciting Terraform concepts! Go ahead and continue your PBL journey with us!
