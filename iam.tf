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

# resource "aws_iam_role_policy" "allow_s3_minecraft_backups" {
#   count = var.s3_backup ? 1 : 0
#   name  = "minecraft_backups"
#   role  = aws_iam_role.minecraft_server_role.name
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = ["s3:*"]
#         Effect = "Allow"
#         Resources = [aws_s3_bucket.minecraft_backups[0].arn,
#         "${aws_s3_bucket.minecraft_backups[0].arn}/*"]
#       }
#     ]
#   })
# }

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