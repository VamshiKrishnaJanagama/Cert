/*
 * EC2 instance IAM profile.
 * If create flag is not set to true, this will use the default role (or provided).
 * If create flag is set to true, this will create a role using default policies.
 * The resulting role name can obtained from an output variable.
 */

data "aws_iam_role" "ec2_role" {
  name = var.ec2_create_role || var.ec2_cert_required ? aws_iam_role.ec2_profile_role[0].name : "EC2SSMDefault"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  count = var.ec2_create_role || var.ec2_cert_required ? 1 : 0
  name  = join("-", ["EC2SSMDefault", data.aws_region.current.name, local.ec2_name])
  role  = data.aws_iam_role.ec2_role.name
}

resource "aws_iam_role" "ec2_profile_role" {
  count              = var.ec2_create_role || var.ec2_cert_required ? 1 : 0
  name               = join("-", ["EC2SSMDefault", data.aws_region.current.name, local.ec2_name])
  tags               = var.tags
  assume_role_policy = data.aws_iam_policy_document.ec2_profile_assume_role_policy[0].json
}

data "aws_iam_policy_document" "ec2_profile_assume_role_policy" {
  count = var.ec2_create_role || var.ec2_cert_required ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# SSM agent permissions.
resource "aws_iam_role_policy_attachment" "ec2_profile_role_policy_aws_managed" {
  for_each   = var.ec2_create_role || var.ec2_cert_required ? local.aws_arn_map : {}
  role       = aws_iam_role.ec2_profile_role[0].name
  policy_arn = each.value
}

# SSM agent logging permissions.
resource "aws_iam_role_policy_attachment" "ec2_profile_role_policy_alight_managed" {
  for_each   = var.ec2_create_role || var.ec2_cert_required ? local.alight_arn_map : {}
  role       = aws_iam_role.ec2_profile_role[0].name
  policy_arn = each.value
}

# Policy document for  ec2 ACM certificate is required

resource "aws_iam_role_policy" "acm_certificate_policy" {
  count  = var.ec2_cert_required ? 1 : 0
  name   = join("-", ["acm-cert", data.aws_region.current.name, local.ec2_name])
  role   = data.aws_iam_role.ec2_role.name
  policy = data.aws_iam_policy_document.acm_cert_profile_role_policy_document[0].json
}
data "aws_iam_policy_document" "acm_cert_profile_role_policy_document" {
  count = var.ec2_cert_required ? 1 : 0
  statement {
    sid    = "DescribeTags"
    effect = "Allow"
    actions = [
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "RenewAndExportInstanceCertificate"
    effect = "Allow"
    actions = [
      "acm:ExportCertificate",
      "acm:RenewCertificate",
      "acm:DescribeCertificate",
      "acm:GetCertificate"
    ]
    resources = [module.private_cert[0].private_cert_arn]
  }
}

--