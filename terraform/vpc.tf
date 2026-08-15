#############################################
# VPC
#############################################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

#############################################
# Subnets — 3 tiers x 2 AZs
#
# Carved out of var.vpc_cidr with cidrsubnet() so the whole network
# plan is derived from a single input instead of a second list of
# CIDRs that has to be kept in sync by hand.
#
#   public       10.0.0.0/24, 10.0.1.0/24    — ALB
#   private-app  10.0.10.0/24, 10.0.11.0/24  — EC2 / ASG
#   private-db   10.0.20.0/24, 10.0.21.0/24  — RDS
#############################################

resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${var.azs[count.index]}"
    Tier = "public"
  }
}

resource "aws_subnet" "private_app" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-private-app-${var.azs[count.index]}"
    Tier = "private-app"
  }
}

resource "aws_subnet" "private_db" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-private-db-${var.azs[count.index]}"
    Tier = "private-db"
  }
}

#############################################
# NAT Gateway — single, not one per AZ
#
# Deliberate cost trade-off (see docs/design-decisions.md and
# docs/tradeoffs.md): halves NAT cost vs. one per AZ. If the NAT's AZ
# has an issue, the app subnet in the *other* AZ loses outbound
# internet until it recovers, but the app stays reachable via the ALB
# regardless — inbound traffic and the DB path don't depend on NAT.
#############################################

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat"
  }

  depends_on = [aws_internet_gateway.this]
}

#############################################
# Route tables
#
# Public  -> IGW
# Private-app -> NAT (single, shared across both AZs)
# Private-db  -> intentionally NOT associated with any route table
# here. That leaves it on the VPC's main (default) route table, which
# has only the implicit local route — no path to the internet in
# either direction. See docs/security.md: "falls back to the VPC
# default table (local-only) — fully isolated by default, not by
# rule alone."
#############################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-private-app-rt"
  }
}

resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

