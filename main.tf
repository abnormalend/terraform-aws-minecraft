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
  name = "minecraft_security"
  description = "Allow access for minecraft server port and ec2 anywhere"
  vpc_id = aws_default_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "minecraft_port" {
  security_group_id = aws_security_group.minecraft_security.id
  description = "Allows whole word access to the minecraft server port"
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 25565
#   to_port     = 25565
  ip_protocol = "tcp"
}

resource "aws_instance" "minecraft_server" {
  ami           = data.aws_ami.amzLinux.id
  instance_type = var.ec2_instance_type
  security_groups = [ aws_security_group.minecraft_security.name ]

  tags = {
    Name = "minecraft_server"
  }
}
