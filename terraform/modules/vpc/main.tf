data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# ── VPC ──
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.tags, { Name = "vpc-streamforge-${var.environment}" })
}

# ── Public Subnets (ALB / Internet Gateway) ──
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name                                    = "subnet-public-${count.index + 1}-streamforge-${var.environment}"
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/eks-streamforge" = "shared"
  })
}

# ── Private Subnets (EKS Nodes — no internet access, use VPC endpoints) ──
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = local.azs[count.index]
  tags = merge(var.tags, {
    Name                                    = "subnet-private-${count.index + 1}-streamforge-${var.environment}"
    "kubernetes.io/role/internal-elb"       = "1"
    "kubernetes.io/cluster/eks-streamforge" = "shared"
  })
}

# ── DB Subnets (DocumentDB — isolated, no routing to internet) ──
resource "aws_subnet" "db" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 20}.0/24"
  availability_zone = local.azs[count.index]
  tags = merge(var.tags, {
    Name = "subnet-db-${count.index + 1}-streamforge-${var.environment}"
  })
}

# ── Internet Gateway (for public subnets / ALB only) ──
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "igw-streamforge-${var.environment}" })
}

# ── Public Route Table → IGW ──
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags, { Name = "rt-public-streamforge-${var.environment}" })
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ── Private Route Table (no NAT — VPC endpoints handle AWS API traffic) ──
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "rt-private-streamforge-${var.environment}" })
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ── DB Route Table (no egress needed) ──
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "rt-db-streamforge-${var.environment}" })
}

resource "aws_route_table_association" "db" {
  count          = 2
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}
