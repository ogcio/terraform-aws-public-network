variable "environment_name"     {  }
variable "private_ip"           { default = "10.0.0.1" }
variable "vpc_cidr_block"       { default = "10.0.0.0/16" }


# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

module "vpc" {

    source = "./vpc"

    cidr_block  = var.vpc_cidr_block
    name        = var.environment_name

}


# -----------------------------------------------------------------------------
# Availability zones
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {}


# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------

module "public_subnets" {

    source                    = "./subnets"

    availability_zones        = data.aws_availability_zones.available.names
    cidr_block_start          = 10
    map_public_ip_on_launch   = true
    name                      = "${var.environment_name}-public-subnet"
    vpc_id                    = module.vpc.id

}


module "private_subnets" {

    source                    = "./subnets"

    availability_zones        = data.aws_availability_zones.available.names
    cidr_block_start          = 20
    map_public_ip_on_launch   = false
    name                      = "${var.environment_name}-private-subnet"
    vpc_id                    = module.vpc.id

}


# -----------------------------------------------------------------------------
# Route tables
# -----------------------------------------------------------------------------

module "public_route_table" {

    source  = "./route_table"

    subnets = module.public_subnets.ids
    vpc_id  = module.vpc.id

}


module "private_route_table" {

    source  = "./route_table"

    subnets = module.private_subnets.ids
    vpc_id  = module.vpc.id

}


# -----------------------------------------------------------------------------
# Internet gateway
# -----------------------------------------------------------------------------

resource "aws_internet_gateway" "gateway" {

    vpc_id  = module.vpc.id

}


# -----------------------------------------------------------------------------
# Elastic ip
# -----------------------------------------------------------------------------

resource "aws_eip" "elastic_ip" {

    vpc                         = true
    associate_with_private_ip   = var.private_ip

    tags = {
        Name = "${var.environment_name}-elastic-ip"
    }

    depends_on = [aws_internet_gateway.gateway]

}


# -----------------------------------------------------------------------------
# NAT gateway
# -----------------------------------------------------------------------------

resource "aws_nat_gateway" "nat_gw" {

    allocation_id     = aws_eip.elastic_ip.id
    subnet_id         = module.public_subnets.ids[0]

    tags = {
        Name = "${var.environment_name}-nat-gateway"
    }

}


# -----------------------------------------------------------------------------
# Routes
# -----------------------------------------------------------------------------

resource "aws_route" "nat_gw_route" {

    route_table_id            = module.private_route_table.id
    nat_gateway_id            = aws_nat_gateway.nat_gw.id
    destination_cidr_block    = "0.0.0.0/0"

}


resource "aws_route" "public_gateway_route" {

    route_table_id            = module.public_route_table.id
    gateway_id                = aws_internet_gateway.gateway.id
    destination_cidr_block    = "0.0.0.0/0"

}


# -----------------------------------------------------------------------------
# Output
# -----------------------------------------------------------------------------

output "availability_zones"     { value = data.aws_availability_zones.available.names }
output "private_subnet_ids"     { value = module.private_subnets.ids }
output "public_ip"              { value = aws_eip.elastic_ip.public_ip }
output "public_subnet_ids"      { value = module.public_subnets.ids }
output "vpc_id"                 { value = module.vpc.id }
output "internet_gateway"       { value = aws_internet_gateway.gateway.id }
