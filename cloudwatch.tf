resource "aws_cloudwatch_log_group" "minecraft_log" {
  name              = "minecraft_log"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "minecraft_server_messages" {
  name              = "minecraft_messages"
  retention_in_days = 30
}

