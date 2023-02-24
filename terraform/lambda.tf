module "autoremediation_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = var.lambda_name
  description   = "Autoremediation lambda"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  lambda_role =   aws_iam_role.lambda_role.arn
  timeout = 15
  create_role = false
  source_path = "../lambda/lambda_function.py"

  architectures = ["arm64"]

  environment_variables = {
    CONFIG_BUCKET = var.bucket_name
    CONFIG_PATH = "autoremediation-config/"
  }

  tags = {
    environment = "dev"
    app = "autoremediation"
  }

  depends_on = [
    aws_iam_role.lambda_role
  ]
}

