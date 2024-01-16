###############################################
################## Webhook ####################
###############################################

resource "aws_lambda_function" "organization_webhook" {
  depends_on = [ archive_file.organization_webhook ]
  function_name = "function_organization_webhook"
  handler       = "index.handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn

  filename = "./lambda/webhook.zip"

  environment {
    variables = {
      # Lambda 함수에 필요한 환경 변수
    }
  }
}

data "archive_file" "organization_webhook" {
  type        = "zip"
  source_file = "./lambda/webhook.py"
  output_path = "./lambda/webhook.zip"
}

###############################################
################# kill chain ##################
###############################################

resource "aws_lambda_function" "kill_chain" {
  depends_on = [ archive_file.kill_chain ]
  function_name = "function_kill_chain"
  handler       = "index.handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn

  filename = "./lambda/webhook.zip"

  environment {
    variables = {
      # Lambda 함수에 필요한 환경 변수
    }
  }
}

data "archive_file" "kill_chain" {
  type        = "zip"
  source_file = "./lambda/kill_chain.py"
  output_path = "./lambda/kill_chainzip"
}

###############################################
################ permission ###################
###############################################

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.organization_webhook.arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3.aws_s3_bucket.bucket.arn
}
