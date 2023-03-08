provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}


# data "aws_availability_zones" "available" {
#   state = "available"
# }

### VPC stuff
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "Minecraft Terraform VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[0]

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Minecraft VPC IG"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_subnet_asso" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}



### Cloudwatch section
resource "aws_cloudwatch_log_group" "minecraft_log" {
  name              = "minecraft_log"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "minecraft_server_messages" {
  name              = "minecraft_messages"
  retention_in_days = 30
}

resource "aws_cloudwatch_metric_alarm" "shutdown_detect" {
  count               = var.shutdown_when_idle ? 1 : 0
  alarm_name          = "shutdown-detector"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.shutdown_minutes / 5
  datapoints_to_alarm = var.shutdown_minutes / 5
  metric_name         = "active_players"
  namespace           = "Minecraft"
  statistic           = "Maximum"
  period              = 300
  alarm_actions       = ["arn:aws:automate:${var.aws_region}:ec2:stop"]

  dimensions = {
    InstanceId = "${aws_instance.minecraft_server.id}"
  }
}

### S3 Section

# Minecraft files are for customizing the minecraft environment.  plugins mods etc
# Minecraft setup files are resources for managing the instance, starting minecraft, things that exist OUTSIDE minecraft and live at the OS level
# Minecraft backups is to store saves of the world data if enabled

resource "aws_s3_bucket" "minecraft_files" {
  bucket_prefix = "minecraft-files"
}

resource "aws_s3_bucket_acl" "minecraft_files_acl" {
  bucket = aws_s3_bucket.minecraft_files.bucket
  acl    = "private"
}

output "minecraft_files_s3_arn" {
  value = aws_s3_bucket.minecraft_files.arn
}

resource "aws_ssm_parameter" "minecraft-files-arn" {
  name  = "minecraft-files-arn"
  type  = "String"
  value = aws_s3_bucket.minecraft_files.arn
}

resource "aws_s3_object" "minecraft_files_object" {
  for_each = fileset("resources/minecraft_files", "**")

  bucket = aws_s3_bucket.minecraft_files.bucket
  key    = each.value
  source = "resources/minecraft_files/${each.value}"
  etag   = filemd5("resources/minecraft_files/${each.value}")
}

resource "aws_s3_bucket" "minecraft_setup_files" {
  bucket_prefix = "minecraft-setup-files"
}

resource "aws_s3_bucket_acl" "minecraft_setup_files_acl" {
  bucket = aws_s3_bucket.minecraft_setup_files.bucket
  acl    = "private"
}

output "minecraft_setup_files_s3_arn" {
  value = aws_s3_bucket.minecraft_setup_files.arn
}

resource "aws_ssm_parameter" "minecraft-setup-files-arn" {
  name  = "minecraft-setup-files-arn"
  type  = "String"
  value = aws_s3_bucket.minecraft_setup_files.arn
}

resource "aws_s3_object" "minecraft_setup_files_object" {
  for_each = fileset("resources/setup_files", "**")

  bucket = aws_s3_bucket.minecraft_setup_files.bucket
  key    = each.value
  source = "resources/setup_files/${each.value}"
  etag   = filemd5("resources/setup_files/${each.value}")
}

resource "aws_s3_bucket" "minecraft_backups" {
  count         = var.s3_backup ? 1 : 0
  bucket_prefix = "minecraft-backups"
}

output "minecraft_backups_s3_arn" {
  value = aws_s3_bucket.minecraft_backups[0].arn
}

resource "aws_ssm_parameter" "minecraft_backups-arn" {
  name  = "minecraft_backups-arn"
  type  = "String"
  value = aws_s3_bucket.minecraft_backups[0].arn
}



### Security Section

resource "aws_security_group" "minecraft_security" {
  name        = "minecraft_security"
  description = "Allow access for minecraft server port and ec2 anywhere"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.minecraft_security.id
  description       = "Allows unrestricted outbound access"
  cidr_ipv4         = "0.0.0.0/0"
  # from_port         = 0
  # to_port           = 0
  ip_protocol = "-1"
  tags        = { Name = "outbound" }
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

### IAM section
resource "aws_iam_role" "minecraft_server_role" {
  name               = "minecraft_server_role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}



data "aws_iam_policy" "CloudWatchAgentServerPolicy" {
  name = "CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.minecraft_server_role.name
  policy_arn = data.aws_iam_policy.CloudWatchAgentServerPolicy.arn
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.minecraft_server_role.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

resource "aws_iam_role_policy" "ec2_describe" {
  name = "ec2_describe"
  role = aws_iam_role.minecraft_server_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ec2:Describe*"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["ec2:*"]
        Effect   = "Allow"
        Resource = aws_instance.minecraft_server.arn
      }
    ]
  })
}

data "aws_iam_policy_document" "allow_minecraft_files" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.minecraft_files.arn,
      "${aws_s3_bucket.minecraft_files.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "allow_s3_minecraft_files" {
  name   = "minecraft_files"
  role   = aws_iam_role.minecraft_server_role.name
  policy = data.aws_iam_policy_document.allow_minecraft_files.json
}

data "aws_iam_policy_document" "allow_minecraft_backups" {
  statement {
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.minecraft_backups[0].arn,
      "${aws_s3_bucket.minecraft_backups[0].arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "allow_s3_minecraft_backups" {
  count  = var.s3_backup ? 1 : 0
  name   = "minecraft_backups"
  role   = aws_iam_role.minecraft_server_role.name
  policy = data.aws_iam_policy_document.allow_minecraft_backups.json
}

resource "aws_iam_role_policy" "dns_permissions" {
  count = var.dns_zone != "" ? 1 : 0
  name  = "dns_permissions"
  role  = aws_iam_role.minecraft_server_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["route53:ChangeResourceRecordSets*"]
        Effect   = "Allow"
        Resource = "arn:aws:route53:::hostedzone/${data.aws_route53_zone.zone_details.zone_id}"
      },
      {
        Action   = ["route53:ListHostedZones"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_permissions" {
  name = "cloudwatch_permissions"
  role = aws_iam_role.minecraft_server_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["cloudwatch:PutMetricData*"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

### Data section

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

#instance stuff

resource "aws_iam_instance_profile" "minecraft_server_profile" {
  name = "minecraft_server_profile"
  role = aws_iam_role.minecraft_server_role.name
}

resource "aws_instance" "minecraft_server" {
  ami                         = data.aws_ami.amzLinux.id
  instance_type               = var.ec2_instance_type
  security_groups             = [aws_security_group.minecraft_security.id]
  iam_instance_profile        = aws_iam_instance_profile.minecraft_server_profile.name
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  tags = {
    Name         = "minecraft_server"
    FileUrl      = "s3://${aws_s3_bucket.minecraft_files.bucket}/"
    BackupUrl    = "s3://${aws_s3_bucket.minecraft_backups[0].bucket}/"
    Schedule     = "gr-office-hours"
    dns_hostname = "terraminecraft"
  }
  user_data_replace_on_change = true
  user_data                   = file("user_data/setup.sh")
}

output "instance_id" {
  value = aws_instance.minecraft_server.id
}