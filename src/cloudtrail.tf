resource "aws_cloudtrail" "organization_cloudtrail" {
  depends_on = [aws_s3_bucket_policy.organization_cloudtrail]

  name                          = "organization-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.organization_cloudtrail.bucket
  s3_key_prefix                 = "prefix"
  include_global_service_events = false
}
