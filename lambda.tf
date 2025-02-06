# Archive for the Lambda handler dependencies
data "archive_file" "tariff_handler_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/handlers/tariff_handler"
  output_path = "${path.module}/src/handlers/tariff_handler.zip"

  depends_on = [null_resource.build_lambdas]
}

# Update the Lambda function to use both layers
resource "aws_lambda_function" "tariff_handler" {
  function_name = "tariff_handler"
  filename      = data.archive_file.tariff_handler_zip.output_path

  handler     = "index.handler"
  runtime     = "nodejs18.x"
  memory_size = 1024
  timeout     = 300

  # This will force Terraform to update the Lambda when the zip content changes
  source_code_hash = data.archive_file.tariff_handler_zip.output_base64sha256

  layers = [
    aws_lambda_layer_version.lambda_deps_layer.arn,
    aws_lambda_layer_version.lambda_utils_layer.arn
  ]

  role = aws_iam_role.handler_lambda_exec.arn
}

resource "null_resource" "build_lambdas" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "./build-lambdas-and-layers.sh"
  }
}
