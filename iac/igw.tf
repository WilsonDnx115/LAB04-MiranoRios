# Salida a internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Project     = "${var.project_name}-igw"
    Environment = terraform.workspace
  }
}
