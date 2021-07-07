output "dc_instance_public_ip" {
  description = "Public IPs assigned to the Application EC2 instance"
  value       = "${aws_instance.docker-compose.0.public_ip}"
}

output "dc_instance_private_ip" {
  description = "Private IP assigned to the Application EC2 instance"
  value       = "${aws_instance.docker-compose.0.private_ip}"
}

output "dc_ssh_connect" {
  description = "Use the following way to connect the Application EC2 instance"
  value       = "ssh -i ${var.PRIVATE_KEY_PATH} ${var.ansible_user}@${aws_instance.docker-compose.0.public_ip}"
}


output "ci_instance_public_ip" {
  description = "Public IPs assigned to the CI EC2 instance"
  value       = "${aws_instance.terraform-ci.0.public_ip}"
}

output "ci_instance_private_ip" {
  description = "Private IP assigned to the CI EC2 instance"
  value       = "${aws_instance.terraform-ci.0.private_ip}"
}

output "ci_ssh_connect" {
  description = "Use the following way to connect the CI EC2 instance"
  value       = "ssh -i ${var.PRIVATE_KEY_PATH} ${var.ansible_user}@${aws_instance.terraform-ci.0.public_ip}"
}

output "url-jenkins" {
  value = "http://${aws_instance.terraform-ci.0.public_ip}:8080"
}

output "url-webapp" {
  description = "Public DNS name assigned to the Application EC2 instance."
  value       = "http://${aws_instance.docker-compose.0.public_dns}"
}

