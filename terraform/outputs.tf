output "instances_public_ips" {
  description = "Public IPs assigned to the EC2 instance"
  value       = "${aws_instance.terraform-ci.0.public_ip}"
}

output "instances_private_ips" {
  description = "Private IPs assigned to the EC2 instance"
  value       = "${aws_instance.terraform-ci.0.private_ip}"
}

output "ssh_connect" {
  description = "Use the following way to connect the EC2 instance"
  value       = "ssh -i ${var.private_key} ubuntu@${aws_instance.terraform-ci.0.public_ip}"
}


output "url-jenkins" {
  value = "http://${aws_instance.terraform-ci.0.public_ip}:8080"
}

#output "url-gitLab" {
#  value = "http://${aws_instance.gitLab.0.public_ip}"
#}
