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

output "minecraft_backups_s3_arn" {
  value = aws_s3_bucket.minecraft_backups[0].arn
}

resource "aws_ssm_parameter" "minecraft_backups-arn" {
  name  = "minecraft_backups-arn"
  type  = "String"
  value = aws_s3_bucket.minecraft_backups[0].arn
}

resource "aws_s3_bucket_object" "resource_files" {
  for_each = fileset("resources/", "*")

  bucket = aws_s3_bucket.minecraft_files.bucket
  key = each.value
  source = "resources/${each.value}"
  etag = filemd5("resources/${each.value}")
}