resource "aws_lambda_layer_version" "lambda_utils_layer" {
  layer_name = "shared_utils"

  # use local filename for now  
  filename         = "${path.module}/src/layers/util-layer/dist/nodejs/index.js"
  source_code_hash = filebase64sha256("${path.module}/src/layers/util-layer/dist/nodejs/index.js")

  compatible_runtimes = ["nodejs18.x"]
}
