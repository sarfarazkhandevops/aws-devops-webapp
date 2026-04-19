resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name = var.vpc_name
  })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-public-${count.index + 1}"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-private-${count.index + 1}"
  })
}

# Elastic IP for NAT
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-nat-eip"
  })
}

# NAT Gateway (in public subnet)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-nat"
  })

  depends_on = [aws_internet_gateway.igw]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  count = length(var.public_subnet_cidr)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-private-rt"
  })
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  count = length(var.private_subnet_cidr)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}