terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  backend "local" {
    path = "D:/GDUQUEO/Personal/ITM/Docencia/2023-2/IaC/Lab1/itmiacvscode/itmiacstate.tfstate"
  }
}

# Configure and downloading plugins for AWS
provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
}