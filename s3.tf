resource "aws_s3_bucket" "minecraft_files" {
  bucket_prefix = "minecraft-files"
}

output "minecraft_files_s3_arn" {
  value = aws_s3_bucket.minecraft_files.arn
}

resource "aws_s3_bucket" "minecraft_backups" {
  count         = var.s3_backup ? 1 : 0
  bucket_prefix = "minecraft-backups"
}

output "minecraft_backups_s3_arn" {
  value = aws_s3_bucket.minecraft_backups[0].arn
}