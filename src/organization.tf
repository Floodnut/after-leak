resource "aws_organizations_organization" "LeakOrganization" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
  ]

  feature_set = "ALL"
}

resource "aws_organizations_account" "root" {
  name  = "root"
  email = "root@leak.org"
}