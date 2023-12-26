resource "aws_iam_role" "lambda_role" {
    // Todo: IAM Role for Lambda
}

resource "aws_iam_role_policy_attachment" "basic-execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}