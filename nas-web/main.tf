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
    name="nas-web"
  cidr_block = "10.0.0.0/16"
}