## Connect AWS and Snowflake

This project will help you get started with AWS and Snowflake.  It has Terraform code to deploy all the AWS permissions
and all the Snowflake permissions and basic infrastructure to start automatically ingesting files from S3.  There is a 
blog post [here](https://abdiels.com/2024/07/03/Snowflake-and-AWS.html) that talks about it in detail.

There are some environment variables that you will need to provide in order for this to work.  Here is a sample of how
a terraform.tfvars could be setup or you can pass the value whichever way so see fit or consider more secure.

snowflake_account  = "The account id that you get when you create a Snowflake account"

snowflake_username = "A snowflake user name with Account admin rights"

snowflake_password = "The password for the corresponding user"

snowflake_region   = "us-east-1" 

snowflake_role     = "ACCOUNTADMIN"

database_name = "The name you want to give your database"

stage_name = "The name you want to give your stage"

schema_name = "The name you want to give your schema"

table_name = "The name you want to give your table"

Before you can run this terraform script, you will need to install SnowSQL. SnowSQL is a CLI client provided by Snowflake.
You can use this [link](https://docs.snowflake.com/en/user-guide/snowsql-install-config) to install SnowSQL if you
don’t have it already. 

Once that is installed, you can proceed to initialize the Terraform working directory with the
command “terraform init”. Then you should proceed to create the infrastructure by using the “terraform apply” command.
That will create all the infrastructure you need to start uploading data.
