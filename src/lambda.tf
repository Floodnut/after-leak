###############################################
################ lambda layer #################
###############################################

resource "null_resource" "pip_install" {
  triggers = {
    shell_hash = "${sha256(file("lambda/requirements.txt"))}"
  }

  provisioner "local-exec" {
    command = "python3 -m pip install -r requirements.txt -t labmda/layer"
  }
}

data "archive_file" "python_layer" {
  type        = "zip"
  source_dir  = "lambda/layer"
  output_path = "lambda/layer.zip"
  depends_on  = [null_resource.pip_install]
}

resource "aws_lambda_layer_version" "python_layer" {
  layer_name          = "python_layer"
  filename            = data.archive_file.python_layer.output_path
  source_code_hash    = data.archive_file.python_layer.output_base64sha256
  compatible_runtimes = ["python3.11", "python3.10", "python3.9"]
}

###############################################
################## Webhook ####################
###############################################

data "archive_file" "organization_webhook" {
  type        = "zip"
  source_file = "./lambda/webhook.py"
  output_path = "./lambda/webhook.zip"
}

resource "aws_lambda_function" "organization_webhook" {
  layers = [ aws_lambda_layer_version.python_layer.arn ]
  function_name = "function_organization_webhook"
  runtime       = "python3.11"
  handler = "webhook.lambda_handler"
  role          = aws_iam_role.lambda_role.arn

  #filename = "./lambda/webhook.zip"
  filename         = data.archive_file.organization_webhook.output_path
  source_code_hash = data.archive_file.organization_webhook.output_base64sha256

  environment {
    variables = {
      # Lambda 함수에 필요한 환경 변수
    }
  }
}

###############################################
################# kill chain ##################
###############################################

data "archive_file" "kill_chain" {
  type        = "zip"
  source_file = "./lambda/kill_chain.py"
  output_path = "./lambda/kill_chain.zip"
}

resource "aws_lambda_function" "kill_chain" {
  layers = [ aws_lambda_layer_version.python_layer.arn ]
  function_name = "function_kill_chain"
  runtime       = "python3.11"
  handler       = "kill_chain.lambda_handler"
  role          = aws_iam_role.lambda_role.arn

  #filename = "./lambda/kill_chain.zip"
  filename         = data.archive_file.kill_chain.output_path
  source_code_hash = data.archive_file.kill_chain.output_base64sha256

  environment {
    variables = {
      # Lambda 함수에 필요한 환경 변수
    }
  }
}

###############################################
############## leak automation ################
###############################################

resource "aws_lambda_function" "leak_automation" {
  function_name = "Leak_Automation"
  handler       = "index.handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn

  image_uri = "${var.docker_repository}/leak:latest"

  environment {
    variables = {
      # Lambda 함수에 필요한 환경 변수
    }
  }
}

###############################################
################ permission ###################
###############################################

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.organization_webhook.arn
  principal     = "s3.amazonaws.com"
}
