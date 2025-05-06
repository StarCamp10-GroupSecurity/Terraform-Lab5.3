locals {
  len_public_subnets  = length(var.vpc_public_subnets)
  len_private_subnets = length(var.vpc_private_subnets)
}

#####################
#        VPC        #
#####################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.proj}-vpc-${var.environment}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.proj}-igw-${var.environment}"
  }
}


#####################
#   Public Subnet   #
#####################

locals {
  create_public_subnets = local.len_public_subnets > 0
}

resource "aws_subnet" "public_subnets" {
  count                   = local.create_public_subnets && (local.len_public_subnets >= length(var.vpc_azs)) ? local.len_public_subnets : 0
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(concat(var.vpc_public_subnets, [""]), count.index)
  availability_zone       = length(regexall("^[a-z]{2}-", element(var.vpc_azs, count.index))) > 0 ? element(var.vpc_azs, count.index) : null
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.proj}-pub-subnet-${var.environment}-${count.index + 1}"
  }
}

#####################
#  Private Subnet   #
#####################
locals {
  create_private_subnets = local.len_private_subnets > 0
}

resource "aws_subnet" "private_subnets" {
  count                   = local.create_private_subnets && (local.len_private_subnets >= length(var.vpc_azs)) ? local.len_private_subnets : 0
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(concat(var.vpc_private_subnets, [""]), count.index)
  availability_zone       = length(regexall("^[a-z]{2}-", element(var.vpc_azs, count.index))) > 0 ? element(var.vpc_azs, count.index) : null
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.proj}-prv-subnet-${var.environment}-${count.index + 1}"
  }
}

// create_private route table
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


#################################
#   Public Subnet Association   #
#################################
resource "aws_route_table_association" "public_subnets_associations" {
  count = local.create_public_subnets ? local.len_public_subnets : 0

  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

#################################
#  Private Subnet Association   #
#################################
resource "aws_route_table_association" "private_subnets_associations" {
  count = local.create_private_subnets ? local.len_private_subnets : 0

  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
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
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "${var.proj}-natgw-${var.environment}"
  }
}