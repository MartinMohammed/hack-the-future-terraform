# Create private subnets in the default VPC
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.48.0/20" # Make sure this doesn't overlap with existing subnets
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "mwaa-private-subnet-1"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.64.0/20" # Make sure this doesn't overlap with existing subnets
  availability_zone = "${var.aws_region}b"

  tags = {
    Name        = "mwaa-private-subnet-2"
    Environment = var.environment
  }
}

# Create NAT Gateway for private subnets
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = data.aws_subnet.public.id

  tags = {
    Name = "mwaa-nat-gateway"
  }
}

# Create route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "mwaa-private-route-table"
  }
}

# Associate route table with private subnets
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private.id
}
