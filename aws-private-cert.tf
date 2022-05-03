data "aws_ssm_parameter" "pca_arn" {
  name = "/terraform/pca_arn"
}

locals {
 cert_name = var.service != null ? "${var.application}-${var.service}-${var.environment}" : "${var.application}-${var.environment}"
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  certificate_authority_arn = data.aws_ssm_parameter.pca_arn.value
  subject_alternative_names = [for x in var.alternative_names : lower(x)]

  tags = merge(var.tags, { Name = var.service != null ? "${var.application}-${var.service}-${var.environment}" : "${var.application}-${var.environment}" })
}

--