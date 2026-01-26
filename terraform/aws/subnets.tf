##################################
# Subnet public
##################################

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "fastapi-microservices-public-subnet"
  }
}

##################################
# Subnet privé EKS - AZ A
##################################

resource "aws_subnet" "private_eks_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "fastapi-microservices-private-eks-a"
  }
}

##################################
# Subnet privé EKS - AZ B
##################################

resource "aws_subnet" "private_eks_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-3b"

  tags = {
    Name = "fastapi-microservices-private-eks-b"
  }
}

##################################
# Subnet privé RDS
##################################

resource "aws_subnet" "private_rds" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "fastapi-microservices-private-rds"
  }
}
