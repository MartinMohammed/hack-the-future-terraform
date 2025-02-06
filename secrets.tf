# create snowflake secret
resource "aws_secretsmanager_secret" "snowflake_secret" {
  name = "snowflake-secret"
}


