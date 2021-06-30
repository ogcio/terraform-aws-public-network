variable "availability_zones"       { default = [] }
variable "cidr_block_start"         { default = 0 }
variable "map_public_ip_on_launch"  { default = true }
variable "name"                     {  }
variable "vpc_id"                   {  }


resource "aws_subnet" "subnet" {
  count = length(var.availability_zones)

  vpc_id = var.vpc_id
  cidr_block = "10.0.${var.cidr_block_start + count.index}.0/24"
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name = "${var.name}-${count.index}"
  }
}


output "ids" { value = aws_subnet.subnet.*.id }
