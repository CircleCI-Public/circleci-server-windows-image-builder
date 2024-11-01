terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "windows_server_2022" {
    most_recent = true
    owners = ["amazon"]
    filter {
      name = "name"
      values = ["Windows_Server-2022-English-Full-Base-*"]
    }
}

resource "aws_security_group" "windows_sg" {
  name ="windows_sg"
  description = "Allow RDP access"
  ingress {
    description = "Allow RDP"
    from_port = "3389"
    to_port ="3389"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = "0"
    to_port ="0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "key" {
  key_name = "orbs_test"
  public_key = file("./key.pub")
}

resource "aws_instance" "windows_server" {
  ami = data.aws_ami.windows_server_2022.id
  instance_type = "t3.medium"
  security_groups = [ aws_security_group.windows_sg.name ]
  key_name = aws_key_pair.key.key_name
  tags = {
    Name = "Windows Server 2022 Orbs Test"
  }
}

