/*
 * Queries the account network.
 */
module "network" {
  source    = "git::codecommit://module-aws-network-data?ref=v2"
  vpc_group = var.vpc_group
  vpc_tier  = var.vpc_tier
}

resource "random_integer" "random_subnet" {
  max = length(module.network.subnet_class_map["private"]) - 1
  min = 0
}

resource "random_string" "ec2_unique_id" {
  length  = 7
  special = false
}

data "aws_organizations_organization" "org" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ssm_parameter" "global_phz" {
  name = "/terraform/privatehostedzone/global/${var.vpc_group}/${var.vpc_tier}"
}
data "aws_ssm_parameter" "regional_phz" {
  name = var.cert_elb_vpc_tier != null ? "/terraform/privatehostedzone/regional/${var.vpc_group}/${var.cert_elb_vpc_tier}" : "/terraform/privatehostedzone/regional/${var.vpc_group}/${var.vpc_tier}"
}

terraform {
  experiments = [module_variable_optional_attrs]
}

/*
 * Static local variables.
 */
locals {
  # AMI query type (i.e., id or name).
  query_ami_id = substr(var.ami_name, 0, 4) == "ami-"

  is_fed = data.aws_organizations_organization.org.id == "o-penzjfasnu"

  ec2_name = var.hostname != "" ? var.hostname : "${var.application}-${var.service}-${random_string.ec2_unique_id.result}-${var.environment}"

  base_ami = {
    o-penzjfasnu = "457704260925"
    o-l0xvscw9dw = "899855515364"
  }

  base_ami_owner = local.base_ami[data.aws_organizations_organization.org.id]

  # ec2 instance profile
  ec2_instance_profile = var.ec2_create_role || var.ec2_cert_required ? aws_iam_instance_profile.ec2_profile[0].name : "EC2SSMDefault"

  # AWS managed policy ARN
  aws_arn_map = (
    {
      "AmazonSSMManagedInstanceCore"    = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      "AmazonSSMDirectoryServiceAccess" = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
    }
  )

  # Alight managed policy ARN
  alight_arn_map = (
    {
      "ADJoinSecretPolicy-Primary"        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/ADJoinSecretPolicy-Primary",
      "alight-ec2-managed-policy-Primary" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/alight-ec2-managed-policy-Primary",
      "alight-ec2-managed-policy-DR"      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/alight-ec2-managed-policy-DR",
      "ADJoinSecretPolicy-DR"             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/ADJoinSecretPolicy-DR"
    }
  )

  # Hostname
  region_initial           = data.aws_region.current.name == "us-east-1" ? "e" : "w"
  hostname                 = var.autoscaling_config.enable == false ? (var.hostname != "" ? join("", [var.hostname, local.region_initial]) : aws_instance.ec2[0].id) : ""
  dns_name                 = var.autoscaling_config.enable == false ? (var.dns_name == "" ? (var.hostname == "" ? aws_instance.ec2[0].id : var.hostname) : var.dns_name) : ""
  cert_domain              = var.cert_elb_subdomain != null ? "${var.cert_elb_subdomain}.${data.aws_ssm_parameter.regional_phz.value}" : "${local.dns_name}.${data.aws_ssm_parameter.regional_phz.value}"
  ec2_primary_region_san   = "${local.dns_name}.${data.aws_ssm_parameter.global_phz.value}"
  tmp_global_phz_value     = data.aws_ssm_parameter.global_phz.value
  ec2_secondary_region_san = var.cert_secondary_region != null ? "${local.dns_name}.${replace(local.tmp_global_phz_value, data.aws_region.current.name, var.cert_secondary_region)}" : ""
  ec2_global_san           = var.cert_elb_subdomain != null ? "${local.dns_name}.${data.aws_ssm_parameter.regional_phz.value}" : ""
  tmp1_global_phz_value    = data.aws_ssm_parameter.global_phz.value
  elb_primary_region_san   = var.cert_elb_subdomain != null ? "${var.cert_elb_subdomain}.${data.aws_ssm_parameter.global_phz.value}" : ""
  elb_secondary_region_san = var.cert_secondary_region != null && var.cert_elb_subdomain != null ? "${var.cert_elb_subdomain}.${replace(local.tmp1_global_phz_value, data.aws_region.current.name, var.cert_secondary_region)}" : ""
  ec2_cert_arn             = var.ec2_cert_required ? module.private_cert[0].private_cert_arn : null

  # Determine az using subnet id logic
  local_subnet_id     = var.deployment_az == null ? module.network.subnet_class_map["private"][random_integer.random_subnet.result] : module.network.subnet_class_az_map["private"][var.deployment_az][0]
  local_lookup_az     = [for k, v in module.network.subnet_class_az_map["private"] : k if v[0] == local.local_subnet_id]
  lookup_patch_az_tag = lookup(var.tags, "PatchAZ", "DNE")
}

module "ebs" {
  source = "git::codecommit://module-aws-ebs?ref=v1"
  count  = var.ebs_attachment == null ? 0 : length(var.ebs_attachment)

  tags = lookup(lookup(var.ebs_attachment, element(keys(var.ebs_attachment), count.index)), "mount_point", null) == null ? { MountPoint = keys(var.ebs_attachment)[count.index] } : { MountPoint = lookup(lookup(var.ebs_attachment, element(keys(var.ebs_attachment), count.index)), "mount_point") }

  availability_zone = aws_instance.ec2[0].availability_zone
  size              = lookup(lookup(var.ebs_attachment, element(keys(var.ebs_attachment), count.index)), "size", null)
  kms_key_id        = lookup(lookup(var.ebs_attachment, element(keys(var.ebs_attachment), count.index)), "kms_key_id", null)
  iops              = lookup(lookup(var.ebs_attachment, element(keys(var.ebs_attachment), count.index)), "iops", null)
  type              = lookup(lookup(var.ebs_attachment, element(keys(var.ebs_attachment), count.index)), "type", null)
  throughput        = lookup(lookup(var.ebs_attachment, element(keys(var.ebs_attachment), count.index)), "throughput", null)

  attachment = tomap({ instance_id = aws_instance.ec2[0].id, device_name = keys(var.ebs_attachment)[count.index] })
}

--