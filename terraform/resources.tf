#resource "aws_key_pair" "terraform" {
#  key_name   = "terraform"
#  public_key = "${file(pathexpand(var.public_key))}"
##  public_key = "${file("~/.ssh/id_rsa.pub")}"
#}

/*
resource "aws_vpc" "my-vpc" {
  cidr_block           = "10.0.0.0/16" # Defines overall VPC address space
  enable_dns_hostnames = true          # Enable DNS hostnames for this VPC
  enable_dns_support   = true          # Enable DNS resolving support for this VPC
  instance_tenancy     = "default"
  enable_classiclink   = "false"

  tags {
    Name = "VPC-my-vpc" # Tag VPC with name
  }
}
*/

resource "aws_instance" "docker-compose" {
  count = "${var.instance_count}"

  #ami = "${lookup(var.amis,var.region)}"
  ami           = "${var.ami}"
  instance_type = "${var.instance}"
  key_name      = "terraform"
  private_ip	= "172.31.13.2"
 
  vpc_security_group_ids = [
    "${aws_security_group.web.id}",
    "${aws_security_group.ssh.id}",
    "${aws_security_group.egress-tls.id}",
    "${aws_security_group.ping-ICMP.id}",
  ]

  
  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_size           = 100
    volume_type           = "io1"
    iops                  = 2000
    encrypted             = true
    delete_on_termination = true
  }

  connection {
    type        = "${var.connection_type}"
    private_key = "${file(pathexpand(var.private_key))}"
    user        = "${var.ansible_user}"
    host        = "${self.private_ip}"
    agent       = false
    timeout     = "2m"
  }

  tags = {
    Name     = "docker-compose-${count.index +1 }"
    Location = "Ireland"
  }
}


resource "aws_instance" "terraform-ci" {
  count = "${var.instance_count}"

  #ami = "${lookup(var.amis,var.region)}"
  ami           = "${var.ami}"
  instance_type = "${var.instance}"
#  key_name      = "${aws_key_pair.demo_key.key_name}"
  key_name       = "terraform"
  private_ip	= "172.31.13.3"

  vpc_security_group_ids = [
#    "${aws_security_group.web.id}",
    "${aws_security_group.ssh.id}",
    "${aws_security_group.egress-tls.id}",
    "${aws_security_group.ping-ICMP.id}",
    "${aws_security_group.web_server.id}"
  ]

  connection {
    type        = "${var.connection_type}"
    private_key = "${file(pathexpand(var.private_key))}"
##    private_key = "${file("~/.ssh/terraform.pem")}"
    user        = "${var.ansible_user}"
    host        = "${self.public_ip}"
##    host        = coalesce(self.public_ip, self.private_ip)
    agent       = false
    timeout     = "2m"
  }

#  depends_on = [
#    aws_pri_ip,
#  ]

  #user_data = "${file("../templates/install_jenkins.sh")}"
  #user_data = "${file("../templates/install_ansible.sh")}"

  # Installing ansible on remote machine
  # Ansible requires Python to be installed on the remote machine as well as the local machine.
  provisioner "remote-exec" {
    inline = ["sudo apt-get update",
#	      "sudo apt-get -qq install python3 -y",
	      "sudo apt-get upgrade python3 -y",
	      "sudo apt-get update",
#	      "sudo DEBIAN_FRONTEND=noninteractive apt-get -y install python3-pip git",
#	      "sudo pip3 install --upgrade pip3",
#	      "sudo pip3 install --upgrade ansible",
	      "sudo apt-get install ansible -y",
	      "echo \"Running Ansible in `pwd`\"",
	      "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa",
	      "echo \"Generated ssh keys pair\"",
	      "eval \"$(ssh-agent -s)\"",
	      "ssh-add ~/.ssh/id_rsa",
	      "echo \"Added SSH key to the ssh-agent\"",
	      "git clone https://github.com/ostasevych/tf-nc.git",
	      "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook ~/tf-nc/playbooks/install_java.yaml",
	      "echo \"Java OpenJDK installed\"",
	      "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook ~/tf-nc/playbooks/install_jenkins.yaml",
	      "echo \"Jenkins installed, available at http://${self.public_ip}:8080 \"",
#	      "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook ~/tf-nc/playbooks/install_docker-compose.yaml",
	      "ansible-playbook -i ${aws_instance.docker-compose.0.private_ip} ~/tf-nc/playbooks/install_docker-compose2.yaml",
#	      "echo \"Docker compose installed\"",
#	      "git remote set-url origin git@github.com:ostasevych/tf-nc.git",
#	      "echo \"Switched GitHub origin to ssh\""
]
  }

  tags = {
    Name     = "terraform-ci-${count.index +1 }"
    Location = "Ireland"
  }
}


resource "aws_security_group" "web" {
  name        = "sec-default-web"
  description = "Security group for web that allows web traffic from internet"
  #vpc_id      = "${aws_vpc.my-vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-default-vpc"
  }
}

resource "aws_security_group" "ssh" {
  name        = "sec-default-ssh"
  description = "Security group for nat instances that allows SSH and VPN traffic from internet"
  #vpc_id      = "${aws_vpc.my-vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-default-vpc"
  }
}

resource "aws_security_group" "egress-tls" {
  name        = "sec-default-egress-tls"
  description = "Default security group that allows inbound and outbound traffic from all instances in the VPC"
  #vpc_id      = "${aws_vpc.my-vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "egress-tls-default-vpc"
  }
}

resource "aws_security_group" "ping-ICMP" {
  name        = "sec-default-ping"
  description = "Default security group that allows to ping the instance"
  #vpc_id      = "${aws_vpc.my-vpc.id}"

  ingress {
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ping-ICMP-default-vpc"
  }
}

# Allow the web app to receive requests on port 8080
resource "aws_security_group" "web_server" {
  name        = "sec-default-web_server"
  description = "Default security group that allows to use port 8080"
  #vpc_id      = "${aws_vpc.my-vpc.id}"
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_server-default-vpc"
  }
}
