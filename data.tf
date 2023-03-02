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

data "aws_route53_zone" "zone_details" {
  name = var.dns_zone
}

output "dns_zone_id" {
  value = data.aws_route53_zone.zone_details.zone_id
}