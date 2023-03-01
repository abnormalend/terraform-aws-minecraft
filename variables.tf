variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "tags" {
  description = "Tags to put on everything"
  type        = map(string)
  default = {
    project = "terraform-aws-minecraft"
  }

}

variable "ec2_instance_type" {
  description = "This is the type of instance to use for the minecraft server"
  type        = string
  default     = "t3a.small"
}