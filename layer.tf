resource "aws_lambda_layer_version" "lambda_deps_layer" {
  layer_name = "shared_deps"

  filename         = data.archive_file.deps_layer_code_zip.output_path
  source_code_hash = data.archive_file.deps_layer_code_zip.output_base64sha256

  compatible_runtimes = ["nodejs18.x"]
}

resource "aws_lambda_layer_version" "lambda_utils_layer" {
  layer_name = "shared_utils"

  filename         = data.archive_file.utils_layer_code_zip.output_path
  source_code_hash = data.archive_file.utils_layer_code_zip.output_base64sha256

  compatible_runtimes = ["nodejs18.x"]
}

data "archive_file" "deps_layer_code_zip" {
  type        = "zip"
  source_dir  = "${path.module}/layers/deps-layer/nodejs"
  output_path = "${path.module}/dist/deps.zip"
}

data "archive_file" "utils_layer_code_zip" {
  type        = "zip"
  source_dir  = "${path.module}/layers/util-layer/nodejs"
  output_path = "${path.module}/dist/utils.zip"
}
