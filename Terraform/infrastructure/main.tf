provider "aws" {
  region  = "ap-south-1"
  profile = "isak"
}

#Creating VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
  
}

#Creating Subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}
#Creating Security Group
resource "aws_security_group" "final_project_sg" {
  name        = "final_project_sg"
  description = "Security group for techaxis final project"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App UI"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Outbount"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "final_project_sg"
  }
}

#Creating key_pair
resource "aws_key_pair" "final-project-key" {
  key_name   = "final-project-key"
  public_key = file(".ssh/my-key.pub")
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

locals {
  instance_user_data = {
    "Jenkins EC2"   = file("${path.module}/scripts/jenkins.sh")
    "Deployment EC2" = file("${path.module}/scripts/deployment.sh")
    "Monitoring EC2" = file("${path.module}/scripts/monitoring.sh")
  }
}

resource "aws_instance" "final_project_instances" {
  count = length(var.instance_names)

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.final-project-key.key_name
  vpc_security_group_ids = [aws_security_group.final_project_sg.id]
  subnet_id              = aws_subnet.public.id
  user_data              = lookup(local.instance_user_data, var.instance_names[count.index], "")

  tags = {
    Name = var.instance_names[count.index]
  }
}