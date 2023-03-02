resource "aws_s3_bucket" "minecraft_files" {
  bucket_prefix = "minecraft-files"
}

output "minecraft_files_s3_arn" {
  value = aws_s3_bucket.minecraft_files.arn
}

resource "aws_ssm_parameter" "minecraft-files-arn" {
  name  = "minecraft-files-arn"
  type  = "String"
  value = aws_s3_bucket.minecraft_files.arn
}

resource "aws_s3_bucket" "minecraft_backups" {
  count         = var.s3_backup ? 1 : 0
  bucket_prefix = "minecraft-backups"
}

resource "aws_s3_bucket_acl" "minecraft_backups_server_access" {
  bucket = aws_s3_bucket.minecraft_backups.arn
  access_control_policy {

    grant {
      grantee {
        id   = aws_iam_role.minecraft_server_role.arn
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    owner {
      id = aws_iam_role.minecraft_server_role.id
    }
  }
}

output "minecraft_backups_s3_arn" {
  value = aws_s3_bucket.minecraft_backups[0].arn
}

resource "aws_ssm_parameter" "minecraft_backups-arn" {
  name  = "minecraft_backups-arn"
  type  = "String"
  value = aws_s3_bucket.minecraft_backups[0].arn
}