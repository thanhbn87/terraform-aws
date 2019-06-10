output public_ips {
 value       = "${compact(concat(aws_eip.this.*.public_ip,list("")))}"
 description = "Public IPs of this ElastiGroup"
}
