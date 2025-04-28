#####################
#        VPC        #
#####################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.proj}-vpc-${var.environment}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.proj}-igw-${var.environment}"
  }
}

// Public Subnet
resource "aws_subnet" "public_subnets" {
  for_each                = toset(var.vpc_public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = var.vpc_azs[index(var.vpc_public_subnets, each.value)]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.proj}-pub-subnet-${var.environment}-${index(var.vpc_public_subnets, each.value) + 1}"
  }
}

// Private Subnet
resource "aws_subnet" "private_subnets" {
  for_each          = toset(var.vpc_private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = var.vpc_azs[index(var.vpc_private_subnets, each.value)]

  tags = {
    Name = "${var.proj}-prv-subnet-${var.environment}-${index(var.vpc_private_subnets, each.value) + 1}"
  }
}

// create public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.proj}-pub-rtb-${var.environment}"
  }
}

// create private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.proj}-prv-rtb-${var.environment}"
  }
}

## public subnet Association
resource "aws_route_table_association" "public_subnets_associations" {
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

## private subnet Association
resource "aws_route_table_association" "private_subnets_associations" {
  for_each       = aws_subnet.private_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route" "route_nat_gw" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id

  timeouts {
    create = "5m"
  }

  depends_on = [aws_route.route_nat_gw]
}

## Network ACL
resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main.id

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  tags = {
    Name = "${var.proj}-nacl-${var.environment}"
  }
}

# NAT Gateway
resource "aws_eip" "main" {
  domain = "vpc"
}


resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = values(aws_subnet.public_subnets)[0].id

  tags = {
    Name = "${var.proj}-natgw-${var.environment}"
  }
}