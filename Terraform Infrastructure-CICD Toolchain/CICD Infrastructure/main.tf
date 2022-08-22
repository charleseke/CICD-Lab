/* This template provisions a VPC with a public subnet, internet gateway, route tables and their associations, security groups,
and EC2 instances to host DevOps toolchain. (Jenkins, Ansible, Docker) */

terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~>3.0"
        }
    }
}

# Configure the AWS provider

provider "aws" {
    region = "us-east-1"
}

# Create a VPC

resource "aws_vpc" "CICD-VPC" {
    cidr_block = var.cidr_block[0]

    tags = {
        Name = "CICD-VPC"
    }
}

# Create Public Subnet

resource "aws_subnet" "CICD-Subnet1" {
    vpc_id = aws_vpc.CICD-VPC.id
    cidr_block = var.cidr_block[1]
    availability_zone = "us-east-1a"

    tags = {
        Name = "CICD-Subnet1"
    }

}

# Create Internet Gateway

resource "aws_internet_gateway" "CICD-IGW" {
    vpc_id = aws_vpc.CICD-VPC.id

    tags = {
        Name = "CICD-IGW"
    }
}

# Create Security Groups

resource "aws_security_group" "CICD-SG" {
    name = "CICD Security Group"
    description = "To allow inbound/outbound traffic to CICD VPC"
    vpc_id = aws_vpc.CICD-VPC.id

    dynamic ingress {
        iterator = port
        for_each = var.ports
         content {
              from_port = port.value
              to_port = port.value
              protocol = "tcp"
              cidr_blocks = ["0.0.0.0/0"]
         }
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      "Name" = "allow traffic"
    }
}

# Create Route Table and Association

resource "aws_route_table" "CICD-RT" {
    vpc_id = aws_vpc.CICD-VPC.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.CICD-IGW.id
    }

    tags = {
      "Name" = "CICD-RT"
    }
}

resource "aws_route_table_association" "CICD_Assn" {
    subnet_id = aws_subnet.CICD-Subnet1.id
    route_table_id = aws_route_table.CICD-RT.id
}

# Create EC2 Instance that auto installs Jenkins at launch using user-data

resource "aws_instance" "Jenkins-Server" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "ServerKey"
  availability_zone = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.CICD-SG.id]
  subnet_id = aws_subnet.CICD-Subnet1.id
  associate_public_ip_address = true
  user_data = file("./InstallJenkins.sh")

  tags = {
    Name = "Jenkins-Server"
  }
}

# Create EC2 Instance that auto installs/configures Ansible as the Control Server

/*resource "aws_instance" "Ansible-Control-Server" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "ServerKey"
  availability_zone = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.CICD-SG.id]
  subnet_id = aws_subnet.CICD-Subnet1.id
  associate_public_ip_address = true
  user_data = file("./InstallAnsibleCN.sh")

  tags = {
    Name = "Ansible-Control-Server"
  }
}*/

# Create EC2 Instance that auto installs/configures Docker as the Ansible Managed Node/DockerHost (App Server)

resource "aws_instance" "Application-Server" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "ServerKey"
  availability_zone = "us-east-1a"
  vpc_security_group_ids = [aws_security_group.CICD-SG.id]
  subnet_id = aws_subnet.CICD-Subnet1.id
  associate_public_ip_address = true
  user_data = file("./Docker.sh")

  tags = {
    Name = "Application-Server"
  }
}

