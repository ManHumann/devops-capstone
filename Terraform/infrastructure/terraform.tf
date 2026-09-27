terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }

    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  required_version = ">=1.2"


  backend "s3" {
    bucket = "manhumann-tf-bucket-state"
    key = "infrastructure/terraform.tfstate"
    region = "ap-south-1"
    profile = "isak"
    dynamodb_table = "my-dynamodb-table"
    encrypt = true
  }

}

