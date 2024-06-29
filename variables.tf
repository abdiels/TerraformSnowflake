variable "snowflake_account" {
  description = "The Snowflake account name."
  type        = string
}

variable "snowflake_username" {
  description = "The Snowflake username."
  type        = string
  sensitive   = true
}

variable "snowflake_password" {
  description = "The Snowflake password."
  type        = string
  sensitive   = true
}

variable "snowflake_region" {
  description = "The Snowflake region."
  type        = string
  default     = "us-east-1"
}

variable "snowflake_role" {
  description = "The Snowflake Role to use."
  type        = string
  default     = "ACCOUNTADMIN"
}

variable external_id {
  description = ""
  type        = string
  default     = "PLACEHOLDER_EXTERNAL_ID"
}

variable "STORAGE_AWS_IAM_USER_ARN" {
  type = string
  default = "arn:aws:iam::123456789012:user/temp"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  default     = "abdiels.snowflake.data"
}

variable "database_name" {
  description = "This is the database name :)"
  type = string
}

variable "schema_name" {
  description = "This is the schema name :)"
  type = string
}

variable "stage_name" {
  description = "This is the stage name :)"
  type = string
}

variable "table_name" {
  description = "This is the table name :)"
  type = string
}

variable "snowpipe_name" {
  description = "This is the snowpipe name :)"
  type = string
  default = "the_snowpipe"
}