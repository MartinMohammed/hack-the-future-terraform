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

  source_bucket_name   = aws_s3_bucket.mwaa_bucket.id
  requirements_s3_path = "requirements.txt"
  plugins_s3_path      = "plugins.zip"

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
