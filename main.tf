provider "aws" {
  region = var.aws_region
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

resource "aws_instance" "minecraft_server" {
  ami           = data.aws_ami.amzLinux.id
  instance_type = var.ec2_instance_type

  tags = var.tags
}