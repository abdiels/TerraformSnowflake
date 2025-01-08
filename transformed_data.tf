resource "snowflake_database" "READY_DB" {
  name                        = "DATA_READY"
  comment                     = "test comment"
}

resource "snowflake_schema" "EVENTS_SCHEMA" {
  database = snowflake_database.READY_DB.name
  name     = "EVENTS_SCHEMA"
  comment  = "A schema."
}

resource "snowflake_table" "EVENTS_TABLE" {
  database        = snowflake_database.READY_DB.name
  schema          = snowflake_schema.EVENTS_SCHEMA.name
  name            = "EVENTS"

  column {
    name     = "EVENT_ID"
    type     = "VARCHAR(100)"
    nullable = true
    comment  = "Event ID"
  }
  column {
    name = "EVENT_TIME"
    type = "TIMESTAMP_NTZ(9)"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
  column {
    name = "EVENT_DOMAIN"
    type     = "VARCHAR(100)"
    nullable = true
    comment  = "The domain that the event belongs to"
  }
  column {
    name = "EVENT_TYPE"
    type     = "VARCHAR(100)"
    nullable = true
    comment  = "The type of event"
  }
  column {
    name     = "EVENT_PAYLOAD"
    type     = "VARCHAR(100)"
    nullable = true
    comment  = "The raw payload for the event"
  }
  column {
    name     = "EVENT_HASH"
    type     = "VARCHAR(100)"
    nullable = true
    comment  = "The raw payload for the event"
  }
}

resource "snowflake_stream" "events_stream" {
  name        = "EVENTS_STREAM"
  database    = snowflake_database.READY_DB.name
  schema      = snowflake_schema.EVENTS_SCHEMA.name
  comment     = "Stream for changes to the source table"

  on_table    = snowflake_table.CRAZY_TABLE.qualified_name

  append_only = true
  show_initial_rows = true

  lifecycle {
    ignore_changes = [
      show_initial_rows
    ]
  }
}

resource "snowflake_task" "my_events_task" {
  name      = "MY_EVENTS_TASK"
  database  = snowflake_database.READY_DB.name
  schema    = snowflake_schema.EVENTS_SCHEMA.name

  user_task_timeout_ms = "3600000" # 1 hour
  comment   = "Load data from external stage to events data table on schedule."
  enabled   = true
  schedule  = "USING CRON */5 * * * * America/New_York"

  sql_statement = <<SQL
      INSERT INTO ${snowflake_table.EVENTS_TABLE.qualified_name}
        (EVENT_ID, EVENT_TIME, EVENT_DOMAIN, EVENT_TYPE, EVENT_PAYLOAD, EVENT_HASH)
      SELECT
        DATA:eventId::STRING AS EVENT_ID,
        DATA:eventTime::TIMESTAMP_NTZ AS EVENT_TIME,
        SPLIT_PART(DATA:eventType::STRING, '.', 1) AS EVENT_DOMAIN,
        SPLIT_PART(DATA:eventType::STRING, '.', 2) AS EVENT_TYPE,
        DATA:eventPayload::STRING AS EVENT_PAYLOAD,
        MD5(DATA:eventPayload::STRING) AS EVENT_HASH
      FROM ${snowflake_stream.events_stream.name}
  SQL

  when = "system$stream_has_data('${snowflake_stream.events_stream.name}')"
}
