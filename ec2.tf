data "aws_ssm_parameter" "linux-sg" {
  name = "/terraform/${var.vpc_group}/${var.vpc_tier}/linux"
}

/*
 * EC2 instance to deploy.
 */
resource "aws_instance" "ec2" {
  count                   = var.autoscaling_config.enable == false ? 1 : 0
  ami                     = var.is_dr ? data.aws_ami.dr_ami[0].id : (local.query_ami_id ? var.ami_name : data.aws_ami.name_filter[0].id)
  instance_type           = var.instance_type
  subnet_id               = local.local_subnet_id
  vpc_security_group_ids  = concat(var.security_group_ids, [data.aws_ssm_parameter.linux-sg.value])
  iam_instance_profile    = local.ec2_instance_profile
  disable_api_termination = var.enable_termination_protection
  tags                    = var.tags
  #volume_tags             = merge(var.tags, { MountPoint = "OS", Name = "${local.ec2_name}-ebs" })
  user_data               = var.vendor_ami_owner == "" ? data.template_cloudinit_config.init_ec2.rendered : null
  key_name                = var.vendor_ami_owner != "" ? var.key_pair_name : null
  monitoring              = true

  # Ignore the following changes since initial deployment...
  lifecycle {
    ignore_changes = [
      user_data,            # user_data modifications
      ebs_optimized,        # instance type change (e.g., m5.large -> c5.xlarge)
      tags["Hostname"],     # tag ignored as its value is generated after ec2 creation and the tag must be applied as a resource below
      tags["RegionalDNS"],  # tag ignored as its value is generated after ec2 creation and the tag must be applied as a resource below
      tags["GlobalDNS"],    # tag ignored as its value is generated after ec2 creation and the tag must be applied as a resource below
      tags["ec2_cert_arn"], # tag ignored as its value is generated after ec2 creation and the tag must be applied as a resource below
      tags["Name"],
      tags["Platform"],
      tags["BackupPlan"],
      tags["BackupName"],
      tags["BackupPolicyOS"],
      tags["AmiVendor"],
      tags["PatchAZ"]
    ]
  }

  dynamic "root_block_device" {
    for_each = var.kms_key_arn == null && var.root_volume_size == null ? [] : [1]
    content {
      encrypted   = true
      kms_key_id  = var.kms_key_arn
      volume_size = var.root_volume_size
    }
  }
}

/*
 * AMI name filter.
 */
data "aws_ami" "name_filter" {
  count       = local.query_ami_id || var.is_dr ? 0 : 1
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [local.base_ami_owner]
}

/*
 * Disaster Recovery AMI
 * For information about these tags, see the following documentation: https://alightsolutionsllc.sharepoint.com/sites/CloudTransform/Wiki/Landing%20Zone/Landing%20Zone%20Tagging%20Design.aspx
 */
data "aws_ami" "dr_ami" {
  count       = var.is_dr ? 1 : 0
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:BackupPlan"
    values = [var.backup_plan]
  }

  filter {
    name   = "tag:BackupName"
    values = [var.backup_name]
  }
}

--