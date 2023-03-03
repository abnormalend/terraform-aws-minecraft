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

#EC2 stuff
variable "ec2_instance_type" {
  description = "This is the type of instance to use for the minecraft server"
  type        = string
  default     = "t3a.micro"
}

variable "ec2_instance_connect" {
  description = "Do we want to allow SSH access via EC2 Instance Connect?"
  type        = bool
  default     = true
}

variable "ec2_ssh_access" {
  description = "Do we want to allow SSH access via EC2 Instance Connect?"
  type = object({
    enabled = bool
  cidr = string })
  default = {
    enabled = false
    cidr    = "127.0.0.1/32"
  }
}

#VPC stuff
variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

#S3 stuff
variable "s3_backup" {
  description = "Do we plan on backing up the minecraft world to S3?"
  type        = bool
  default     = true
}

#DNS Stuff
variable "dns_zone" {
  description = "if set, we can use this to update dns"
  type        = string
  default     = ""
}


#Auto shutdown Stuff
variable "shutdown_when_idle" {
  description = "Do we want to turn off the server when it is not being used?"
  type        = bool
  default     = true
}

variable "shutdown_minutes" {
  description = "If shutdown_when_idle is being used, how long before we shut down?"
  type        = number
  default     = 30
}