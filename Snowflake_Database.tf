resource "snowflake_database" "CRAZY_DB" {
  name                        = var.database_name
  comment                     = "test comment"
  data_retention_time_in_days = 0
}

resource "snowflake_schema" "CRAZY_SCHEMA" {
  database = snowflake_database.CRAZY_DB.name
  name     = var.schema_name
  comment  = "A schema."

  is_transient        = true # For our purposes, we don't want to retain the data.
  is_managed          = false
  data_retention_days = 0
}

resource "snowflake_stage" "CRAZY_STAGE" {
  name        = var.stage_name
  url         = "s3://${var.bucket_name}/"
  database    = snowflake_database.CRAZY_DB.name
  schema      = snowflake_schema.CRAZY_SCHEMA.name
  storage_integration = snowflake_storage_integration.aws_s3_integration.name
  file_format = "FORMAT_NAME = ${snowflake_database.CRAZY_DB.name}.${snowflake_schema.CRAZY_SCHEMA.name}.${snowflake_file_format.ndjson_gz_file_format.name}"
  depends_on = [snowflake_file_format.ndjson_gz_file_format]
}

resource "snowflake_table" "CRAZY_TABLE" {
  database        = snowflake_database.CRAZY_DB.name
  schema          = snowflake_schema.CRAZY_SCHEMA.name
  name            = var.table_name
  change_tracking = true
#   cluster_by      = var.cluster_by    <-- Talk about clustering the table, but leave it out of this example

  column {
    name = "DATA"
    type = "VARIANT"
  }
  column {
    name = "INGESTED_TIMESTAMP"
    type = "TIMESTAMP_NTZ(9)"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}

resource "snowflake_pipe" "snowpipe" {
  depends_on = [snowflake_table.CRAZY_TABLE,snowflake_stage.CRAZY_STAGE, null_resource.update_snowflake_integration]
  copy_statement = "COPY INTO ${snowflake_table.CRAZY_TABLE.database}.${snowflake_table.CRAZY_TABLE.schema}.${snowflake_table.CRAZY_TABLE.name} (DATA) FROM (SELECT $1 FROM @${snowflake_stage.CRAZY_STAGE.database}.${snowflake_stage.CRAZY_STAGE.schema}.${snowflake_stage.CRAZY_STAGE.name})"
  database       = snowflake_database.CRAZY_DB.name
  name           = var.snowpipe_name
  schema         = snowflake_schema.CRAZY_SCHEMA.name
  auto_ingest = true
}

resource "snowflake_file_format" "ndjson_gz_file_format" {
  name              = "LOAD_NDJSON"
  database          = var.database_name
  schema            = var.schema_name
  compression       = "AUTO"

  binary_format     = "HEX"
  date_format       = "AUTO"
  time_format       = "AUTO"
  timestamp_format  = "AUTO"

  format_type       = "JSON"

  depends_on = [snowflake_database.CRAZY_DB, snowflake_schema.CRAZY_SCHEMA]
}
