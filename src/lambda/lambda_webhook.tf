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