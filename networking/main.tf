# ----------------- Networking/ main.tf -----

#Availability Zones Declaration 

data "aws_availability_zones" "available" {}


resource "random_integer" "random" {
  min = 1
  max = 100
}

#Random Shuffle

resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}


resource "aws_vpc" "hiba_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Names = "hiba_vpc-${random_integer.random.id}"
  }
  # Create the new VPC before destroying the old one> for the IGW to be associated to the new one. 

  lifecycle {
    create_before_destroy = true
  }

}

# Add the public subnets

resource "aws_subnet" "hiba_public_subnet" {
  count                   = var.public_sn_count
  vpc_id                  = aws_vpc.hiba_vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_list.result[count.index]
  tags = {
    Name = "hiba_public_subnet-${count.index + 1}"
  }
}

## Private Subnets
resource "aws_subnet" "hiba_private_subnet" {
  count                   = var.private_sn_count
  vpc_id                  = aws_vpc.hiba_vpc.id
  cidr_block              = var.private_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.az_list.result[count.index]
  tags = {
    Name = "hiba_private_subnet-${count.index + 1}"
  }
}

# RDS Subnet group

resource "aws_db_subnet_group" "hiba_rds_subnetgroup" {
  count      = var.db_subnet_group == true ? 1 : 0
  name       = "hiba_rds_subnetgroup"
  subnet_ids = aws_subnet.hiba_private_subnet.*.id
  tags = {
    Name = "hiba_rds_sng"
  }
}


#-------Route Table Association ------

resource "aws_route_table_association" "hiba_public_assoc" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.hiba_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.hiba_public_rt.id
}

#----------IGW -------

resource "aws_internet_gateway" "hiba_internet_gateway" {
  vpc_id = aws_vpc.hiba_vpc.id

  tags = {
    Name = "hiba_igw"
  }
}

#-----------Route Tables ------

resource "aws_route_table" "hiba_public_rt" {
  vpc_id = aws_vpc.hiba_vpc.id

  tags = {
    Name = "hiba_public"
  }
}

#--------Default Route -----------

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.hiba_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.hiba_internet_gateway.id
}

#-----------deault Route Table ------

resource "aws_default_route_table" "hiba_private_rt" {
  default_route_table_id = aws_vpc.hiba_vpc.default_route_table_id

  tags = {
    Name = "hiba_private"
  }
}

#  Security Group

resource "aws_security_group" "hiba_sg" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.hiba_vpc.id



  #public Security Group
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


