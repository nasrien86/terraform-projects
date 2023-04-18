terraform {
   required_providers {
      aws = {
        source = "hashicorp/aws"
        version="~> 4.0"
      }
   } 
}

# configuration for aws 
provider "aws" {
  region = "us-east-1"
}

#create a vpc
resource "aws_vpc" "nas-web"{
  enable_dns_hostnames = true
  cidr_block = "10.0.0.0/16"
}
#create a subnet1
resource "aws_subnet" "my_subnet1" {
  vpc_id            = aws_vpc.nas-web.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"
}
#create subnet2
resource "aws_subnet" "my_subnet2" {
  vpc_id            = aws_vpc.nas-web.id
  cidr_block        = "10.0.100.0/24"
  availability_zone = "us-east-1b"
}
#security group for instances
resource "aws_security_group" "nas-web-sg" {
  name  = "allow https"
  vpc_id   = aws_vpc.nas-web.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
# Create internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.nas-web.id
}

# Create route table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.nas-web.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

#route table associations
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_subnet1.id
  route_table_id = aws_route_table.my_route_table.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.my_subnet2.id
  route_table_id = aws_route_table.my_route_table.id
}

#With Latest Version Of Launch Template
resource "aws_launch_configuration" "asg-config" {
  name_prefix     = "aws-asg"
  image_id        = "ami-069aabeee6f53e7bf"
  instance_type   = "t2.micro"
  user_data       = file("user-data.sh")
  security_groups = [aws_security_group.nas-web-sg.id]
  associate_public_ip_address = true
  
}

resource "aws_autoscaling_group" "my-asg" {
  
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2
  
    launch_configuration  = aws_launch_configuration.asg-config.id
    vpc_zone_identifier       = [aws_subnet.my_subnet1.id, aws_subnet.my_subnet2.id]
  
  
  
}