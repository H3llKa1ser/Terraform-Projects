data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "rt" {
  cidr_block           = "10.50.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.engagement_name}-vpc" }
}

resource "aws_internet_gateway" "rt" {
  vpc_id = aws_vpc.rt.id
  tags   = { Name = "${var.engagement_name}-igw" }
}

# --- Public subnet: redirectors + bastion + NAT live here ---
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.rt.id
  cidr_block              = "10.50.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "${var.engagement_name}-public" }
}

# --- Private subnet: team server lives here, no public IP ---
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.rt.id
  cidr_block        = "10.50.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = { Name = "${var.engagement_name}-private" }
}

# --- Public routing via IGW ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.rt.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rt.id
  }
  tags = { Name = "${var.engagement_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- NAT gateway so the private team server can reach out (updates, etc.) ---
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.engagement_name}-nat-eip" }
}

resource "aws_nat_gateway" "rt" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags          = { Name = "${var.engagement_name}-nat" }
  depends_on    = [aws_internet_gateway.rt]
}

# --- Private routing via NAT ---
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.rt.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.rt.id
  }
  tags = { Name = "${var.engagement_name}-private-rt" }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
