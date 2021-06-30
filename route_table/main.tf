variable "subnets"      {  }
variable "vpc_id"       {  }


resource "aws_route_table" "default" {
  vpc_id = var.vpc_id
}


resource "aws_route_table_association" "default" {
  count = length(var.subnets)

  route_table_id = aws_route_table.default.id
  subnet_id      = var.subnets[count.index]
}


output "id" { value = aws_route_table.default.id }
