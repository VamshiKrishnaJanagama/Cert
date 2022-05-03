/*
 * Output values.
 */

output "arn" {
  value       = var.autoscaling_config.enable == false ? aws_instance.ec2[0].arn : ""
  description = "The instance arn."
}

output "ec2_instance_id" {
  value       = var.autoscaling_config.enable == false ? aws_instance.ec2[0].id : ""
  description = "The instance id."
}

output "ec2_instance_az" {
  value       = var.autoscaling_config.enable == false ? aws_instance.ec2[0].availability_zone : null
  description = "The instance availability zone."
}

output "ec2_instance_role_name" {
  value       = data.aws_iam_role.ec2_role.name
  description = "The instance profile role."
}

output "private_ip" {
  value       = var.autoscaling_config.enable == false ? aws_instance.ec2[0].private_ip : ""
  description = "The private ip address."
}

output "root_block_device_id" {
  value       = var.autoscaling_config.enable == false ? aws_instance.ec2[0].root_block_device[0].volume_id : ""
  description = "The root OS volume id."
}

output "root_block_device_size" {
  value       = var.autoscaling_config.enable == false ? aws_instance.ec2[0].root_block_device[0].volume_size : ""
  description = "The root OS volume size."
}

output "apps_block_device_id" {
  value       = var.autoscaling_config.enable == false ? aws_instance.ec2[0].ebs_block_device[*].volume_id : []
  description = "The apps volume id."
}

output "apps_block_device_size" {
  value       = var.autoscaling_config.enable == false ? aws_instance.ec2[0].ebs_block_device[*].volume_size : []
  description = "The apps volume size."
}

output "regional_dns_fqdn" {
  value       = var.autoscaling_config.enable == false ? module.ec2_dns_regional_record.domain : ""
  description = "Regional domain name"
}

output "global_dns_fqdn" {
  value       = var.autoscaling_config.enable == false ? module.ec2_dns_global_record.domain : ""
  description = "Global domain name"
}

output "ec2_cert_arn" {
  #  value       = var.ec2_cert_required ? module.private_cert[0].private_cert_arn : ""
  value       = local.ec2_cert_arn
  description = "EC2 Instance private cert arn"
}

output "instance_az" {
  value       = local.local_lookup_az[0]
  description = "Determined AZ that the instance will be deployed into based on vpc group/subnet id."
}

output "autoscaling_group" {
  value       = var.autoscaling_config.enable == true ? aws_autoscaling_group.ec2_asg[0].id : ""
  description = "Autoscaling group name"
}

--