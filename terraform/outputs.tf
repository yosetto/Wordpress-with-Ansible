output "vpc_id" {
   value = ["${module.vpc.vpc_id}"]
}

output "vpc_public_subnets" {
   value = ["${module.vpc.public_subnets}"]
}

output "wordpress_ids" {
   value = ["${aws_instance.wordpress.*.id}"]
}

output "ip_addresses" {
   value = ["${aws_instance.wordpress.*.id}"]
}
