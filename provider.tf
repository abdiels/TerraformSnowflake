terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.19.0"
    }
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.92.0"
    }
  }
}

provider "aws" {
  shared_config_files      = ["/Users/asanchez/.aws/config"]
  shared_credentials_files = ["/Users/asanchez/.aws/credentials"]
  profile                  = "default"
  region                   = "us-east-1"
}

provider "snowflake" {
  account  = "${var.snowflake_account}.${var.snowflake_region}"
  user = var.snowflake_username
  password = var.snowflake_password
  role     = var.snowflake_role
}

resource snowflake_warehouse TERRAFORM_WH{
  name = "TERRAFORM_WH"
  warehouse_size = "XSMALL"
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true
}