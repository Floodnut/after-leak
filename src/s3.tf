resource "aws_s3_bucket" "organization_cloudtrail" {
  bucket = var.organization_cloudtrail
  acl    = "private"

  logging {
    target_bucket = aws_s3_bucket.organization_cloudtrail.bucket
    target_prefix = "${var.organization_cloudtrail}/"
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.organization_cloudtrail.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.organization_webhook.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "AWSLogs/"
    filter_suffix       = ".log"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_s3_bucket_policy" "organization_cloudtrail" {
  bucket = aws_s3_bucket.organization_cloudtrail.bucket
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
}
