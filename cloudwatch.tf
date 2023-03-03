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
  alarm_actions       = ["arn:aws:automate:${var.aws_region}:ec2:stop"]

  dimensions = {
    InstanceId = "${aws_instance.minecraft_server.id}"
  }
}