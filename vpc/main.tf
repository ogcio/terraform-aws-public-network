variable "cidr_block"           { default = "10.0.0.0/16" }
variable "name"                 {  }


resource "aws_vpc" "default" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.name
  }
}


output "id" { value = aws_vpc.default.id }
