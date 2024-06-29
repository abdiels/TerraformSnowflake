# Step 1: Create a Temporary IAM Role
resource "aws_iam_role" "temporary_snowflake_role" {
  name = "temporary_snowflake_role"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "s3.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

# Step 2: Create the Snowflake Storage Integration
resource "snowflake_storage_integration" "aws_s3_integration" {
  name                      = "AWS_S3_INTEGRATION"
  storage_provider          = "S3"
  storage_aws_role_arn      = aws_iam_role.temporary_snowflake_role.arn
  enabled                   = true
  storage_allowed_locations = ["s3://${var.bucket_name}/"]

  lifecycle {
    ignore_changes = [
      storage_aws_role_arn
    ]
  }
}

# Step 3: Create the Actual IAM Role with the Actual ARN
resource "aws_iam_role" "snowflake_role" {
  name = "snowflake_role"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "${snowflake_storage_integration.aws_s3_integration.storage_aws_iam_user_arn}"
        },
        "Action": "sts:AssumeRole",
        "Condition": {
          "StringEquals": {
            "sts:ExternalId": "${snowflake_storage_integration.aws_s3_integration.storage_aws_external_id}"
          }
        }
      }
    ]
  }
  EOF

  depends_on = [snowflake_storage_integration.aws_s3_integration]
}

# Step 4: Create the Policy to give snowflake access
resource "aws_iam_policy" "snowflake_s3_policy" {
  name        = "snowflake_s3_policy"
  description = "Policy to allow Snowflake access to S3 bucket"
  policy      = <<EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "s3:PutObject",
                  "s3:GetObject",
                  "s3:GetObjectVersion",
                  "s3:DeleteObject",
                  "s3:DeleteObjectVersion"
              ],
              "Resource": "arn:aws:s3:::${var.bucket_name}/*"
          },
          {
              "Effect": "Allow",
              "Action": [
                  "s3:ListBucket",
                  "s3:GetBucketLocation"
              ],
              "Resource": "arn:aws:s3:::${var.bucket_name}",
              "Condition": {
                  "StringLike": {
                      "s3:prefix": [
                          "*"
                      ]
                  }
              }
          }
      ]
  }
  EOF
}

# Step 5: Attach the policy to the role
resource "aws_iam_role_policy_attachment" "snowflake_role_policy_attachment" {
  role       = aws_iam_role.snowflake_role.name
  policy_arn = aws_iam_policy.snowflake_s3_policy.arn
}

# Step 6: Update the Snowflake Storage Integration to Use the Actual IAM Role
resource "null_resource" "update_snowflake_integration" {
  provisioner "local-exec" {
    environment = {
      SNOWSQL_PWD = var.snowflake_password
    }
    command = <<EOT
    snowsql -a '${var.snowflake_account}.${var.snowflake_region}' -u '${var.snowflake_username}' -r '${var.snowflake_role}' -q "alter storage integration ${snowflake_storage_integration.aws_s3_integration.name} set STORAGE_AWS_ROLE_ARN='${aws_iam_role.snowflake_role.arn}'"
    EOT
  }

  depends_on = [
    aws_iam_role.snowflake_role,
    aws_iam_role_policy_attachment.snowflake_role_policy_attachment
  ]
}

# Step 7: Enable notifications on S3 so that the integration works as the files arrive
resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = var.bucket_name
  queue {
    queue_arn     = snowflake_pipe.snowpipe.notification_channel
    events        = ["s3:ObjectCreated:*"]
  }

}

# Step 8: Detach Policies from Temporary IAM Role
resource "null_resource" "detach_policies_from_temp_role" {
  provisioner "local-exec" {
    command = <<EOT
    attached_policies=$(aws iam list-attached-role-policies --role-name ${aws_iam_role.temporary_snowflake_role.name} --query "AttachedPolicies[].PolicyArn" --output text)
    for policy_arn in $attached_policies; do
      aws iam detach-role-policy --role-name ${aws_iam_role.temporary_snowflake_role.name} --policy-arn $policy_arn
    done
    EOT
  }
}

# Step 9: Delete the Temporary IAM Role
resource "null_resource" "cleanup_temporary_role" {
  provisioner "local-exec" {
    command = "aws iam delete-role --role-name ${aws_iam_role.temporary_snowflake_role.name}"
  }

  depends_on = [null_resource.detach_policies_from_temp_role]
}

