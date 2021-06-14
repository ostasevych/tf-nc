output "dc_instance_public_ip" {
  description = "Public IPs assigned to the Docker Compose EC2 instance"
  value       = "${aws_instance.docker-compose.0.public_ip}"
}

output "dc_instance_private_ip" {
  description = "Private IP assigned to the Docker Compose EC2 instance"
  value       = "${aws_instance.docker-compose.0.private_ip}"
}

output "dc_ssh_connect" {
  description = "Use the following way to connect the Docker Compose EC2 instance"
  value       = "ssh -i ${var.private_key} ubuntu@${aws_instance.docker-compose.0.public_ip}"
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
  value       = "ssh -i ${var.private_key} ubuntu@${aws_instance.terraform-ci.0.public_ip}"
}


output "url-jenkins" {
  value = "http://${aws_instance.terraform-ci.0.public_ip}:8080"
}

