/*
 * Required input variables.
 */

variable "ami_name" {
  type        = string
  description = "The base ami name to utilize (ex. 'alight-rhel78base_1.*')."
}

variable "instance_type" {
  type        = string
  description = "The instance type to utilize."
}

variable "vpc_group" {
  type        = string
  description = "VPC Group you are looking to pull network information for. These values are custom based on VPC creation process."
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to associate with."
}

variable "tags" {
  type        = map(string)
  description = "Tags used to sort/reference the ec2 resource."
}

variable "application" {
  type        = string
  description = "Project name, all lowercase with no spaces (ie. idb, eloise, ect.)"
}

variable "service" {
  type        = string
  description = "Service name, all lowercase with no spaces but dashes okay (ie. ui, transmit, ect.)"
}

variable "environment" {
  type        = string
  description = "Environment name, all lowercase with no spaces (ie. lb, dv, qa, ect.)"
}

/*
 * Optional input variables.
 */

# unused
# variable "base_ami_owner" {
#   type        = string
#   description = "The base ami owner id (if using ami name). Defaults to the app-shared-services account id."
#   default     = "899855515364"
# }

variable "vendor_ami_owner" {
  type        = string
  description = "Vendor Ami Owner should only be passed in if this instance is to be treated as an appliance. This means that NO Alight patching and operational tools will be installed and run on this instance. It is up to the service owner to maintain this instance and keep it current working with our infrastructure operational teams. Setting this value will automatically attach a AmiVendor tag key with the value passed in"
  default     = ""
}

variable "vpc_tier" {
  type        = string
  description = "VPC Tier you are looking to pull network information for. Valid Values are web,app and db."
  default     = "app"

  validation {
    condition     = can(regex("^(web|app|db)$", var.vpc_tier))
    error_message = "The vpc tier valid values are 'web', 'app', 'db'."
  }
}

variable "ec2_create_role" {
  type        = bool
  default     = false
  description = "Indicates if an EC2 role should be created"
 
}

variable "deployment_az" {
  type        = string
  default     = null
  description = "AZ to deploy the instance in (a, b, c, ...). If null, a random AZ is selected"
}

variable "efs_mounts" {
  description = "EFS ID, optional access point ID and mount directory"
  type        = map(object({ efs_id = string, access_point_id = optional(string), mount_point = string }))
  default     = {}
}

variable "user_data_content" {
  description = "User data script to be executed upon ec2 initialization"
  type        = string
  default     = null
}

variable "hostname" {
  type        = string
  default     = ""
  description = "Used to set the computer name / host name in the OS.  This hostname is used for integration with additional operational agents (i.e. netbackup, puppet, etc…)"
}

variable "dns_name" {
  type        = string
  default     = ""
  description = "Used to set the dns name in our global and regional aws private hosted zones"
}

variable "enable_termination_protection" {
  type        = bool
  default     = false
  description = "Enable instance termination protection"
}

variable "cert_secondary_region" {
  type        = string
  default     = null
  description = "This will ONLY be used if ec2_cert_required is true. Add an aws region here if this EC2 instance requires a backup in a DR region. This input should be the DR region for this deployment. It will add the DR SAN values to the certificate. ex. us-west-2. If no DR is needed for this instance, keep this value null.  "
}
variable "cert_elb_subdomain" {
  type        = string
  default     = null
  description = "This will ONLY be used if ec2_cert_required is true. Set this value if NLB does not terminate TLS. Top level domain is generated in ec2 module"
}

variable "cert_elb_vpc_tier" {
  type        = string
  default     = null
  description = "This will ONLY be used if ec2_cert_required is true. Additionally, this will only be used when the ELB is in a different VPC Tier than the EC2 instance. Set this value if NLB does not terminate TLS. Top level domain is generated in ec2 module"
}

variable "ec2_cert_required" {
  type        = bool
  default     = false
  description = "This will ONLY be used if ec2_cert_required is true."
}

variable "is_dr" {
  type        = bool
  default     = false
  description = "Will determine if the AMI passed in should be used or if we need to fetch the AMI based on backup tags."
}

variable "backup_plan" {
  type        = string
  default     = ""
  description = "Required if is_dr is true. DR backup plan policy for this EC2 instance."
}

variable "backup_name" {
  type        = string
  default     = ""
  description = "Required if is_dr is true. DR backup name for this EC2 instance."
}

variable "backup_OS" {
  type        = bool
  default     = true
  description = "Indicates if an EC2 instance will be AUTO tagged for backup. If this value is set to true, the user can NOT pass in a tag key of 'BackupPolicyOS'. If user wants to override default 'BackupPolicyOS' value, then set var.backup_OS to false and pass in tag key 'BackupPolicyOS' with custom policy."
}

variable "puppet_role" {
  type        = string
  default     = "base"
  description = "Will be required as platforms built out. Base is an unconfigured ec2."
}

variable "puppet_environment" {
  type        = string
  default     = "production"
  description = "The puppet environment the ec2 will be configured against."

  validation {
    condition     = contains(["production", "development"], var.puppet_environment)
    error_message = "Only allowed environments are production and development."
  }
}

variable "puppet_trusted_facts" {
  type        = object({ pp_cluster = optional(string) })
  default     = {}
  description = "Optional puppet facts needed via puppet role."
}

variable "root_volume_size" {
  description = "number in GB for root volume AKA OS disk"
  type        = number
  default     = null
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "KMS Key ARN if not using the AccountLevelKey"
}

variable "key_pair_name" {
  type        = string
  default     = null
  description = "Key name of the key pair to use for the instance. This value will only be accepted if the vendor_ami_owner is passed in."
}

variable "autoscaling_config" {
  description = "Autoscaling configuration"
  type = object({
    enable                     = bool
    placement_grp_strategy     = string,
    autoscaling_ami_id         = string,
    desired_capacity           = number,
    health_check_type          = string,
    health_check_grace_period  = number,
    cpu_utilization_scale_up   = number,
    cpu_utilization_scale_dwn  = number,
    ec2_scale_up_adjustment    = number,
    ec2_scale_dwn_adjustment   = number,
    eval_period_scale_up       = string,
    eval_period_scale_dwn      = string,
    healthcheck_fail_threshold = number,
    auto_scale_subnet          = list(string),
    size                       = object({ min = number, max = number })
  })
  default = {
    enable                     = false
    placement_grp_strategy     = "spread"
    desired_capacity           = 0
    health_check_type          = null
    health_check_grace_period  = 300
    ec2_scale_up_adjustment    = 1
    ec2_scale_dwn_adjustment   = -1
    cpu_utilization_scale_up   = 80
    cpu_utilization_scale_dwn  = 30
    eval_period_scale_up       = "5"
    eval_period_scale_dwn      = "5"
    healthcheck_fail_threshold = 3
    auto_scale_subnet          = null
    autoscaling_ami_id         = ""

    size = { min = 0
    max = 0 }
  }
}

variable "ebs_attachment" {
  type = map(object({
    size       = number,
    kms_key_id = optional(string),
    iops       = optional(number),
    type       = optional(string),
    throughput = optional(number),
    mount_point = optional(string)
  }))
  default     = null
  description = "Map used to create and attach EBS volumes"
}

--