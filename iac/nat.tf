# ips para nat
resource "aws_eip" "nat_a" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Project = "${terraform.workspace}-eip-nat-a"
  }
}

resource "aws_eip" "nat_b" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Project = "${terraform.workspace}-eip-nat-b"
  }
}

