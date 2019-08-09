variable "name" {}
variable "project_env" { default = "Bastion" }
variable "instance_type" {}
variable "ami" {}

variable "delete_on_termination" { default = false }
variable "iam_instance_profile" {}
variable "protect_termination" { default = true }
variable "cpu_credits" { default = "unlimited" }

variable "key_name" {}
variable "vpc_security_group_ids" { default = [] }
variable "subnet_id" {}
variable "volume_size" { default = "20" }
variable "ebs_optimized" { default = true }
