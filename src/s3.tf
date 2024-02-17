resource "aws_s3_bucket" "organization_cloudtrail" {
  bucket = var.organization_cloudtrail
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.organization_cloudtrail.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.organization_webhook.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "AWSLogs/"
    filter_suffix       = ".log"
  }
}

resource "aws_s3_bucket_policy" "organization_cloudtrail" {
  bucket = aws_s3_bucket.organization_cloudtrail.bucket
  policy = aws_iam_policy.cloudtrail_bucket_policy
}
