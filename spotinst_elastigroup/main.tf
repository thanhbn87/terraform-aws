/// Providers:
provider "spotinst" {
  token   = "${var.spotinst_token}"
  account = "${var.spotinst_account}"
}

provider "aws" {
  region  = "${var.region}"
  profile = "${var.aws_profile}"
}

/// Local vars:
locals {
  tags = [
    {
      "key"   = "SpotInst"
      "value" = "true"
    },
    {
      "key"   = "Env"
      "value" = "${var.project_env}"
    }
  ]

  ebs_block_device_more = "${length(var.ebs_block_device) > 0 ? true : false}"
  ebs_block_device      = {
    more      = "${var.ebs_block_device}"
    only_root = [{
      device_name           = "${var.ebs_device_name}"
      volume_type           = "${var.ebs_volume_type}"
      volume_size           = "${var.ebs_volume_size}"
      delete_on_termination = "${var.ebs_delete_on_termination}"
    }]
  }

}

/// Resources:
resource "aws_eip" "this" {
  count    = "${var.desired_capacity}"
  vpc      = true
  tags     = {
    Env    = "${var.project_env}"
    Name   = "${lower(var.name)}-${format("%02d", count.index + 1)}"
  }
}

resource "spotinst_elastigroup_aws" "this" {
  // General:
  name        = "${var.name}"
  description = "${var.desc}"
  product     = "${var.product}"
  region      = "${var.region}"
  subnet_ids  = ["${var.subnet_ids}"]
  tags        = "${concat(local.tags,var.tags)}"

  // Capacity
  min_size         = "${var.min_size}" 
  max_size         = "${var.max_size}" 
  desired_capacity = "${var.desired_capacity}" 
  capacity_unit    = "${var.capacity_unit}" 

  // Launch Config
  image_id                  = "${var.image_id}"
  iam_instance_profile      = "${var.iam_instance_profile}"
  key_name                  = "${var.key_name}"
  security_groups           = ["${var.security_groups}"]
  enable_monitoring         = "${var.enable_monitoring}"
  ebs_optimized             = "${var.ebs_optimized}"
  placement_tenancy         = "${var.placement_tenancy}"
  user_data                 = "${var.user_data}"
  health_check_type         = "${var.health_check_type}"
  health_check_grace_period = "${var.health_check_grace_period}"
  elastic_ips               = ["${compact(concat(aws_eip.this.*.id,list("")))}"]
  network_interface         = ["${var.network_interface}"]
  ebs_block_device          = "${local.ebs_block_device["${local.ebs_block_device_more ? "more" : "only_root"}"]}"

  // Compute
  instance_types_ondemand       = "${var.instance_types_ondemand}"
  instance_types_spot           = "${var.instance_types_spot}"
  instance_types_preferred_spot = "${var.instance_types_preferred_spot}"
  instance_types_weights        = "${var.instance_types_weights}"

  // Load balancer

  // Strategy
  orientation                = "${var.orientation}"
  spot_percentage            = "${var.spot_percentage}"
  draining_timeout           = "${var.draining_timeout}"
  lifetime_period            = "${var.lifetime_period}"
  fallback_to_ondemand       = "${var.fallback_to_ondemand}"
  utilize_reserved_instances = "${var.utilize_reserved_instances}"
  revert_to_spot             = ["${var.revert_to_spot}"]

  // Stateful
  block_devices_mode    = "${var.block_devices_mode}"
  persist_root_device   = "${var.persist_root_device}"
  persist_block_devices = "${var.persist_block_devices}"
  persist_private_ip    = "${var.persist_private_ip}"

  lifecycle {
    ignore_changes = [
      "desired_capacity",
    ] 
  }
}

resource "aws_route53_record" "local" {
  count   = "${var.route53_local ? "${var.desired_capacity}" : 0}"
  zone_id = "${var.private_zone_id}"
  name    = "${lower(var.name)}-${format("%02d", count.index + 1)}.${var.domain_local}"
  type    = "A"
  ttl     = "${var.private_record_ttl}"
  records = ["${coalesce(element(concat(aws_eip.this.*.private_ip,list("")),count.index),"${var.route53_temp_ip}")}"]
  depends_on = [ "spotinst_elastigroup_aws.this", "aws_eip.this" ]
}
