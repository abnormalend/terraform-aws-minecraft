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
  type = bool
  default = true
}

variable "ec2_ssh_access" {
  description = "Do we want to allow SSH access via EC2 Instance Connect?"
  type = object({
    enabled = bool
    cidr = string})
  default = {
    enabled = false
    cidr = "127.0.0.1/32"
  }
}

#VPC stuff
variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}