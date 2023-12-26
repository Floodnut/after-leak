resource "aws_s3_bucket" "organization-cloudtrail" {
  bucket        = "organization-cloudtrail"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "organization-cloudtrail" {
  bucket = aws_s3_bucket.organization-cloudtrail.id
  policy = data.aws_iam_policy_document.organization-trail-s3-put.json
}