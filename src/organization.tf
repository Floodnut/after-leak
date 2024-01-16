resource "aws_organizations_account" "root" {
  name  = "root"
  email = "root@leak.org"
}

resource "aws_organizations_policy" "scp" {
  name    = "example"
  content = data.aws_iam_policy_document.example.json
}