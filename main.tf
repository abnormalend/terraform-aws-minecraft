provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# data "aws_availability_zones" "available" {
#   state = "available"
# }

data "aws_ami" "amzLinux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "minecraft_security" {
  name        = "minecraft_security"
  description = "Allow access for minecraft server port and ec2 anywhere"
  vpc_id      = aws_default_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "minecraft_port" {
  security_group_id = aws_security_group.minecraft_security.id
  description       = "Allows whole word access to the minecraft server port"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 25565
  to_port           = 25565
  ip_protocol       = "tcp"
  tags              = { Name = "Minecraft" }
}

resource "aws_vpc_security_group_ingress_rule" "instance_connect_port" {
  count             = var.ec2_instance_connect ? 1 : 0
  security_group_id = aws_security_group.minecraft_security.id
  description       = "Allows shell access through EC2 instance connect"
  cidr_ipv4         = "3.16.146.0/29"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  tags              = { Name = "EC2 Instance Connect" }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_access_port" {
  count             = var.ec2_ssh_access.enabled ? 1 : 0
  security_group_id = aws_security_group.minecraft_security.id
  description       = "Allows shell access from a given ip/range"
  cidr_ipv4         = var.ec2_ssh_access.cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  tags              = { Name = "SSH Access" }
}

resource "aws_iam_service_linked_role" "minecraft_server_role" {
  aws_service_name   = "ec2.amazonaws.com"
}

# resource "aws_iam_role" "minecraft_server_role" {
#   name               = "minecraft_server_role"
#   assume_role_policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Action": "sts:AssumeRole",
#             "Principal": {
#                "Service": "ec2.amazonaws.com"
#             },
#             "Effect": "Allow",
#             "Sid": ""
#         }
#     ]
# }
# EOF
# }

resource "aws_iam_instance_profile" "minecraft_server_profile" {
  name = "server_profile"
  role = aws_iam_role.minecraft_server_role.name
}

resource "aws_instance" "minecraft_server" {
  ami                  = data.aws_ami.amzLinux.id
  instance_type        = var.ec2_instance_type
  security_groups      = [aws_security_group.minecraft_security.name]
  iam_instance_profile = aws_iam_instance_profile.minecraft_server_profile.name
  tags = {
    Name = "minecraft_server"
  }
}

