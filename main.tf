terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5"
    }
  }
}

provider "aws" {
  region                   = var.region
  shared_config_files      = [var.aws_config_path]
  shared_credentials_files = [var.aws_credentials_path]
}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name" = "MyTerraformVPC"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    "Name" = "BuilderYard-public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    "Name" = "BuilderYard-private-subnet"
  }
}

resource "aws_internet_gateway" "mygateway" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "publicRT" {
  vpc_id = aws_vpc.myvpc.id

  #Cualquier consulta que llegue debe ser redirigida al gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygateway.id
  }

  tags = {
    "Name" = "BuilderYard-public-RT"
  }
}


resource "aws_route_table_association" "publicRTassociation" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.publicRT.id
}


resource "aws_security_group" "public_security_group" {
  name        = "public_security_group"
  description = "Allow ssh and http conections"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_key_pair" "key" {
  key_name = var.key_name
}

resource "aws_instance" "bastion_host" {
  ami                         = var.ec2_ami
  instance_type               = var.instance_type
  key_name                    = data.aws_key_pair.key.key_name
  subnet_id                   = aws_subnet.public-subnet.id
  security_groups             = [aws_security_group.public_security_group.id]
  associate_public_ip_address = true
  user_data                   = file("install.sh")

  tags = {
    "Name" = "bastion_host"
  }
}

resource "aws_security_group" "private_security_group" {
  name        = "private_security_group"
  description = "Only allow http requests from intarnal hosts"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description     = "http"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_security_group.id]
  }

  ingress {
    description     = "SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "ec2_private_server" {
  ami             = var.ec2_ami
  instance_type   = var.instance_type
  key_name        = data.aws_key_pair.key.key_name
  subnet_id       = aws_subnet.private-subnet.id
  security_groups = [aws_security_group.private_security_group.id]
  user_data       = file("install.sh")

  tags = {
    "Name" = "ec2_private_server"
  }
}

## {{{ Private EC2 instance connection with internet

resource "aws_eip" "my_eip" {

}

resource "aws_nat_gateway" "my_natgateway" {
  subnet_id     = aws_subnet.public-subnet.id
  allocation_id = aws_eip.my_eip.id
}

resource "aws_route_table" "privateRT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my_natgateway.id
  }

  tags = {
    "Name" = "BuilderYard-private-RT"
  }
}

resource "aws_route_table_association" "privateRTassociation" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.privateRT.id
}

## }}}