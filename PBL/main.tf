 provider "aws" {
      region = var.region
 }
 
  # Create VPC
 resource "aws_vpc" "main" {
 cidr_block                     = var.vpc_cidr
 enable_dns_support             = var.enable_dns_support 
 enable_dns_hostnames           = var.enable_dns_support
 #enable_classiclink_dns_support = var.enable_classiclink

 }
 # Get list of availability zones
 data "aws_availability_zones" "available" {
        state = "available"
 }
# Create public subnet1
 resource "aws_subnet" "public" {
  count  = var.preferred_number_of_public_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_public_subnets   
  vpc_id = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    var.tags,
    {
      Name = format("%s-PublicSubnet-%s", var.name, count.index)
    },
  )

}

# Create private subnet
resource "aws_subnet" "private" {
  count  = var.preferred_number_of_private_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_private_subnets   
  vpc_id = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    var.tags,
    {
      Name = format("%s-PrivateSubnet-%s", var.name, count.index)
    } 
  )

}

## Create internet gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
     var.tags,
     {
        Name = format("%s-%s-%s", var.name, aws_vpc.main.id, "IGW")
     },
  )
}

## Create 1 NAT Gateways and 1 Elastic IP (EIP) addresses
resource "aws_eip" "nat_eip" {
  domain       = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = merge(
    var.tags,
    {
      Name = format("%s-EIP-%s", var.name, var.environment)
    },
  )
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public.*.id, 0)
  depends_on    = [aws_internet_gateway.igw]

  tags = merge(
    var.tags,
    {
      Name = format("%s-Nat-%s", var.name, var.environment)
    },
  )
}

