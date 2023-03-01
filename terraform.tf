terraform {

  cloud {
    organization = "abnormalend-terraform"
    workspaces {
      name = "terraform-aws-minecraft"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.15.0"
    }
  }
  required_version = "~> 1.3.0"
}

