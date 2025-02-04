module "mwaa" {
  source  = "aws-ia/mwaa/aws"
  version = "0.0.6"

  name              = "hack-the-future-mwaa"
  airflow_version   = "2.7.2" # Using a more recent version
  environment_class = "mw1.small"

  vpc_id             = data.aws_vpc.default.id
  private_subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  min_workers           = 1
  max_workers           = 25
  webserver_access_mode = "PUBLIC_ONLY" # Change to PRIVATE_ONLY for production

  source_bucket_arn = aws_s3_bucket.mwaa_bucket.arn

  logging_configuration = {
    dag_processing_logs = {
      enabled   = true
      log_level = "INFO"
    }

    scheduler_logs = {
      enabled   = true
      log_level = "INFO"
    }

    task_logs = {
      enabled   = true
      log_level = "INFO"
    }

    webserver_logs = {
      enabled   = true
      log_level = "INFO"
    }

    worker_logs = {
      enabled   = true
      log_level = "INFO"
    }
  }

  airflow_configuration_options = {
    "core.load_default_connections" = "false"
    "core.load_examples"            = "false"
    "webserver.dag_default_view"    = "tree"
    "webserver.dag_orientation"     = "TB"
    "logging.logging_level"         = "INFO"
  }

  tags = {
    Environment = var.environment
    Project     = "hack-the-future"
  }
}

# Create S3 bucket for MWAA
resource "aws_s3_bucket" "mwaa_bucket" {
  bucket = "hack-the-future-mwaa-${data.aws_caller_identity.current.account_id}"
}

# Enable versioning for the MWAA bucket
resource "aws_s3_bucket_versioning" "mwaa_bucket_versioning" {
  bucket = aws_s3_bucket.mwaa_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to the MWAA bucket
resource "aws_s3_bucket_public_access_block" "mwaa_bucket_public_access_block" {
  bucket = aws_s3_bucket.mwaa_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
