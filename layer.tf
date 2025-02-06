resource "aws_lambda_layer_version" "lambda_utils_layer" {
  layer_name = "shared_utils"

  filename            = "${path.module}/dist/layers/util-layer.zip"
  source_code_hash    = filebase64sha256("${path.module}/dist/layers/util-layer.zip")
  compatible_runtimes = ["nodejs18.x"]
}
