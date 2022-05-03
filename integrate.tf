module "ec2_linux" {
  source             = "git::codecommit://module-aws-ec2-linux?ref=%BRANCH%"
  ami_name           = "alight_rhel79base*"
  instance_type      = "t3.medium"
  security_group_ids = ["sg-03eee855906d90157"] # policy-staging-app-linux
  vpc_group          = "policy-staging"
  application        = "tf-module-ci-test"
  ec2_cert_required  = "true"
  environment        = "dv"
  service            = "terraform"
  tags               = {}
  ebs_attachment     = {
    "/dev/sdh" = {size = 10}
    "/dev/sdb" = {
      size = 20,
      kms_key_id = "arn:aws:kms:us-east-1:686437426460:key/9cab08a8-839d-4d7e-87ab-66237d4d264d",
      type = "gp3",
      attachment = true,
      mount_point = "/apps"
    }
  }
}

# module "ec2_linux_host" {
#   source             = "git::codecommit://module-aws-ec2-linux?ref=%BRANCH%"
#   ami_name           = "alight_rhel79base*"
#   instance_type      = "t3.medium"
#   security_group_ids = ["sg-03eee855906d90157"] # policy-staging-app-linux
#   vpc_group          = "policy-staging"
#   application        = "tf-module-ci-test"
#   environment        = "dv"
#   service            = "terraform"
#   tags               = {}
#   autoscaling_config = {
#     enable                     = true
#     desired_capacity           = 2
#     health_check_type          = "ELB"
#     health_check_grace_period  = 900
#     ec2_scale_up_adjustment    = 1
#     ec2_scale_dwn_adjustment   = -1
#     cpu_utilization_scale_up   = 80
#     cpu_utilization_scale_dwn  = 30
#     eval_period_scale_up       = "5"
#     eval_period_scale_dwn      = "5"
#     healthcheck_fail_threshold = 3
#     placement_grp_strategy     = "spread"
#     autoscaling_ami_id         = "ami-0cdb0402f7af1d05a"
#     auto_scale_subnet          = null
#     size = {
#       min = 1
#       max = 5
#      }
#   }
# }

module "ec2_linux_upgrade" {
  source             = "git::codecommit://module-aws-ec2-linux?ref=%LATEST%"
  ami_name           = "alight_rhel79base*"
  instance_type      = "t3.medium"
  security_group_ids = ["sg-03eee855906d90157"] # policy-staging-app-linux
  vpc_group          = "policy-staging"
  application        = "tf-module-ci-test1"
  environment        = "dv"
  service            = "terraform"
  ec2_cert_required  = "true"
  tags               = {}
}

--