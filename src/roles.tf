###############################################
################ Lambda Roles #################
###############################################
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

###############################################
########### pipeline-automation ###############
###############################################

resource "aws_iam_role" "pipeline-automation" {
    name = "pipeline-automation"

    assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "accessAutomationTables",
                "Effect": "Allow",
                "Action": [
                    "dynamodb:*"
                ],
                "Resource": [
                    "arn:aws:dynamodb:ap-northeast-2:234355188026:table/automation-log",
                    "arn:aws:dynamodb:ap-northeast-2:234355188026:table/automation-state"
                ]
            },
            {
                "Sid": "accessLambda",
                "Effect": "Allow",
                "Action": [
                    "lambda:InvokeFunction",
                    "lambda:InvokeAsync"
                ],
                "Resource": [
                    "*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": "logs:CreateLogGroup",
                "Resource": "arn:aws:logs:ap-northeast-2:234355188026:*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ],
                "Resource": [
                    "*"
                ]
            }
        ]
    })
}

resource "aws_iam_role" "lambda_role" {
    name = "ScpAttachDetachAccess"

    assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "organizations:ListPoliciesForTarget",
                "organizations:ListRoots",
                "organizations:ListAccounts",
                "organizations:ListTargetsForPolicy",
                "organizations:DetachPolicy",
                "organizations:AttachPolicy",
                "organizations:DescribeAccount",
                "organizations:ListParents",
                "organizations:DescribePolicy",
                "organizations:ListPolicies"
            ],
            "Resource": "*"
        }
    ]
})
}

data "aws_iam_policy_document" "organization-trail-s3-put" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.organization-cloudtrail.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/organization"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.organization-cloudtrail.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/organization"]
    }
  }
}


resource "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  source_json = <<POLICY
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Action": "s3:GetBucketAcl",
        "Resource": "${aws_s3_bucket.cloudtrail_bucket.arn}"
        },
        {
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": "${aws_s3_bucket.cloudtrail_bucket.arn}/*",
        "Condition": {
            "StringEquals": {
            "s3:x-amz-acl": "bucket-owner-full-control"
            }
        }
        }
    ]
    }
    POLICY
}