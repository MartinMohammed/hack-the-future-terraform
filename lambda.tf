# Archive for the Lambda handler
data "archive_file" "tariff_handler_zip" {
  type        = "zip"
  source_dir  = "${path.module}/dist/handlers/tariff_handler"
  output_path = "${path.module}/dist/handlers/tariff_handler.zip"

  depends_on = [null_resource.build_lambdas]
}

resource "aws_lambda_function" "tariff_handler" {
  function_name = "tariff_handler"
  filename      = data.archive_file.tariff_handler_zip.output_path

  handler     = "index.handler"
  runtime     = "nodejs18.x"
  memory_size = 1024
  timeout     = 300

  source_code_hash = data.archive_file.tariff_handler_zip.output_base64sha256

  layers = [
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
