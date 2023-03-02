provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
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

resource "aws_iam_instance_profile" "minecraft_server_profile" {
  name = "minecraft_server_profile"
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

output "instance_id" {
  value = aws_instance.minecraft_server.id
}

resource "aws_cloudwatch_log_group" "minecraft_log" {
  name              = "minecraft_log"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "minecraft_server_messages" {
  name              = "minecraft_messages"
  retention_in_days = 30
}