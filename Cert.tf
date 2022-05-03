module "private_cert" {
  count             = var.ec2_cert_required ? 1 : 0
  source            = "git::codecommit://module-aws-private-cert?ref=AWS-17215-master"
  application       = "${local.hostname}-${var.application}"
  domain_name       = local.cert_domain
  alternative_names = compact([local.ec2_secondary_region_san, local.ec2_primary_region_san, local.ec2_global_san, local.elb_primary_region_san, local.elb_secondary_region_san])
  environment       = var.environment
  tags              = var.tags
}

resource "aws_ec2_tag" "cert_arn" {
  count       = var.ec2_cert_required ? 1 : 0
  resource_id = aws_instance.ec2[0].id
  key         = "ec2_cert_arn"
  value       = local.ec2_cert_arn
}
--