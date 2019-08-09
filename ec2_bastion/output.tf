output "id" {
  value = "${aws_instance.bastion.id}"
}

output "bastion_eip_id" {
  value = "${aws_eip.eip_bastion.id}"
}

output "bastion_eip_instance" {
  value = "${aws_eip.eip_bastion.instance}"
}

output "bastion_eip_private" {
  value = "${aws_eip.eip_bastion.private_ip}"
}

output "bastion_eip_public" {
  value = "${aws_eip.eip_bastion.public_ip}"
}
