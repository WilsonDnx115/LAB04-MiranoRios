# nat gateways
resource "aws_nat_gateway" "nat_gw_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id 

  tags = {
    Project = "${terraform.workspace}-nat-gw-a"
  }
}

resource "aws_nat_gateway" "nat_gw_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id 

  tags = {
    Project = "${terraform.workspace}-nat-gw-b"
  }
}