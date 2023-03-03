provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}


# data "aws_availability_zones" "available" {
#   state = "available"
# }



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
    Name          = "minecraft_server"
    s3FileUrl   = "s3://${aws_s3_bucket.minecraft_files.bucket}/"
    s3BackupUrl = "s3://${aws_s3_bucket.minecraft_backups[0].bucket}/"
    Schedule      = "office-hours"
  }
  user_data_replace_on_change = true
  user_data                   = file("user_data/setup.sh")
}




output "instance_id" {
  value = aws_instance.minecraft_server.id
}

