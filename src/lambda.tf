###############################################
################## Webhook ####################
###############################################

resource "aws_lambda_function" "organization_webhook" {
  function_name = "function_organization_webhook"
  handler       = "index.handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn

  filename = "${path.module}/lambda_function_payload.zip"

  environment {
    variables = {
      # Lambda 함수에 필요한 환경 변수
    }
  }
}

###############################################
################# kill chain ##################
###############################################

resource "aws_lambda_function" "kill_chain" {
  function_name = "function_kill_chain"
  handler       = "index.handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn

  filename = "${path.module}/lambda_function_payload.zip"

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
  source_arn    = module.s3.aws_s3_bucket.bucket.arn
}
