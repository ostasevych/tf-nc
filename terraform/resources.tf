resource "aws_key_pair" "generated_key" {
    key_name   = "${uuid()}"
    public_key = "${tls_private_key.t.public_key_openssh}"
}
provider "tls" {}
resource "tls_private_key" "t" {
    algorithm = "RSA"
}

provider "local" {}

resource "local_file" "private_key" {
    content  = "${tls_private_key.t.private_key_pem}"
    filename = "${var.PRIVATE_KEY_PATH}"
    provisioner "local-exec" {
        command = "chmod 600 ${var.PRIVATE_KEY_PATH}"
    }
}

resource "local_file" "public_key" {
    content  = "${tls_private_key.t.public_key_openssh}"
    filename = "${var.PUBLIC_KEY_PATH}"
    provisioner "local-exec" {
        command = "chmod 644 ${var.PUBLIC_KEY_PATH}"
    }
}

#resource "aws_key_pair" "my-key-pair" {
#  key_name   = "my-key-pair"
##  public_key = "${file(pathexpand(var.public_key))}"
#  public_key = "${file(var.PUBLIC_KEY_PATH)}"
#}

resource "aws_vpc" "my-vpc" {
  cidr_block           = "10.0.0.0/16" # Defines overall VPC address space
  enable_dns_hostnames = true          # Enable DNS hostnames for this VPC
  enable_dns_support   = true          # Enable DNS resolving support for this VPC
  instance_tenancy     = "default"
  enable_classiclink   = "false"

  tags = {
    Name = "VPC-my-vpc" # Tag VPC with name
  }
}

resource "aws_subnet" "my-subnet-1" {
    vpc_id = "${aws_vpc.my-vpc.id}"
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
#    availability_zone = "${lookup(var.az,count.index)}"
    availability_zone = "eu-west-1a"

    tags = {
        Name = "my-subnet-1"
    }
}


resource "aws_internet_gateway" "my-igw" {
    vpc_id = "${aws_vpc.my-vpc.id}"
    tags = {
        Name = "my-igw"
    }
}

resource "aws_route_table" "my-public-crt" {
    vpc_id = "${aws_vpc.my-vpc.id}"
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = "${aws_internet_gateway.my-igw.id}" 
    }
    
    tags = {
        Name = "my-public-crt"
    }
}

resource "aws_route_table_association" "my-crta-public-subnet-1"{
    subnet_id = "${aws_subnet.my-subnet-1.id}"
    route_table_id = "${aws_route_table.my-public-crt.id}"
}

resource "aws_security_group" "web" {
  name        = "sec-default-web"
  description = "Security group for web that allows web traffic from internet"
  vpc_id      = "${aws_vpc.my-vpc.id}"

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
  vpc_id      = "${aws_vpc.my-vpc.id}"

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
  vpc_id      = "${aws_vpc.my-vpc.id}"

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
  vpc_id      = "${aws_vpc.my-vpc.id}"

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
  vpc_id      = "${aws_vpc.my-vpc.id}"
  
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


resource "aws_s3_bucket" "nc-bucket-data" {
  bucket = "${var.name_prefix}-nc-data"
  acl    = "private"

  versioning {
    enabled = true
  }
  force_destroy = true
  policy = jsonencode({
   Version: "2012-10-17",
   Statement: [
    {
      Sid: "KMS Manager",
      Effect: "Allow",
      Principal: "*",
      Action: [
        "s3:*"
      ],
      Resource: [
        "arn:aws:s3:::${var.name_prefix}-nc-data",
        "arn:aws:s3:::${var.name_prefix}-nc-data/*"
      ]
    },
    {
      Sid: "Iam user bucket",
      Effect: "Allow",
      Principal: "*",
      Action: [
        "s3:ListBucket"
      ],
      Resource: ["arn:aws:s3:::${var.name_prefix}-nc-data"]
    },
    {
      Sid: "Iam user objects",
      Effect: "Allow",
      Principal: "*",
      Action: [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:DeleteObject"
      ],
      Resource: ["arn:aws:s3:::${var.name_prefix}-nc-data/*"]
    }
  ]
})
}

# s3 block all public access to bucket
resource "aws_s3_bucket_public_access_block" "nc-bucket-pubaccessblock-data" {
  bucket                  = aws_s3_bucket.nc-bucket-data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_instance" "docker-compose" {
  count = "${var.instance_count}"
  ami = "${lookup(var.amis,var.region)}"
#  ami           = "${var.ami}"
  instance_type = "${var.instance}"

# VPC
  subnet_id = "${aws_subnet.my-subnet-1.id}"

# the Public SSH key
key_name      = aws_key_pair.generated_key.key_name
#  key_name = "${aws_key_pair.my-key-pair.id}"
#  key_name      = "terraform"

# Defining private IP
#  private_ip	= "172.31.32.101"
#  private_ip = "${aws_subnet.my-subnet-1.private_ip}"
#   private_ip = "10.0.1.2"
  private_ip = "${lookup(var.private_ips,count.index)}"


# Security Group
  vpc_security_group_ids = [
    "${aws_security_group.web.id}",
    "${aws_security_group.ssh.id}",
    "${aws_security_group.egress-tls.id}",
    "${aws_security_group.ping-ICMP.id}",
  ]

# Defining EBS volumes

#  ebs_block_device {
#    device_name           = "/dev/sdg"
#    volume_size           = 10
#    volume_type           = "gp2"
#    iops                  = 0
#    encrypted             = true
#    delete_on_termination = true
#  }

  connection {
     type        = "${var.connection_type}"
     private_key = "${tls_private_key.t.private_key_pem}"
     user        = "${var.ansible_user}"
     host        = "${self.public_ip}"
     agent       = false
     timeout     = "2m"
  }

#  provisioner "file" {
#    source = var.PRIVATE_KEY_PATH
#    destination = "~/.ssh/${var.PRIVATE_KEY_PATH}"
#   }

# Adding public key to the docker-compose VM

  provisioner "local-exec" {
    command = "echo \"${file(var.PUBLIC_KEY_PATH)}\" > ./authorized_keys; chmod 600 authorized_keys"
}

  provisioner "file" {
    source = "authorized_keys"
    destination = "~/authorized_keys"
   }

  provisioner "remote-exec" {
    inline = [
        "cat ~/authorized_keys >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys; rm -f authorized_keys"
    ]
  }
  provisioner "local-exec" {
    command = "rm -f authorized_keys"
  }

  tags = {
    Name     = "docker-compose-${count.index +1 }"
    Location = "Ireland"
  }
}


resource "aws_instance" "terraform-ci" {
  count = "${var.instance_count}"
  ami = "${lookup(var.amis,var.region)}"
#  ami           = "${var.ami}"
  instance_type = "${var.instance}"

# VPC
  subnet_id = "${aws_subnet.my-subnet-1.id}"

# the Public SSH key
  key_name       = aws_key_pair.generated_key.key_name
# key_name       = "${aws_key_pair.my-key-pair.id}"
# key_name       = "terraform"


# Defining private ip address
  private_ip = "${lookup(var.private_ips,count.index+1)}"

# Security Group
  vpc_security_group_ids = [
#   "${aws_security_group.web.id}",
    "${aws_security_group.ssh.id}",
    "${aws_security_group.egress-tls.id}",
    "${aws_security_group.ping-ICMP.id}",
    "${aws_security_group.web_server.id}"
  ]

  connection {
     type        = "${var.connection_type}"
     private_key = "${tls_private_key.t.private_key_pem}"
     user        = "${var.ansible_user}"
     host        = "${self.public_ip}"
     agent       = false
     timeout     = "2m"
  }


  #user_data = "${file("../templates/install_jenkins.sh")}"
  #user_data = "${file("../templates/install_ansible.sh")}"

# Sending private key to the VM

  provisioner "file" {
    source = var.PRIVATE_KEY_PATH
    destination = "~/.ssh/${var.PRIVATE_KEY_PATH}"
   }


# Installing ansible on remote machine
# Ansible requires Python to be installed on the remote machine as well as the local machine.
  
  provisioner "remote-exec" {
    inline = [
	      "chmod 400 ~/.ssh/${var.PRIVATE_KEY_PATH}",

	      "sudo apt update && sudo apt upgrade -y",
	      "sudo apt install python3 -y",
	      "sudo apt install python3-pip -y",
	      "sudo apt install git -y",
	      "sudo apt update && sudo apt upgrade -y",
	      "sudo apt install ansible -y",
#	      "sudo pip install --upgrade pip",
#	      "sudo pip install --upgrade ansible",
	      "if [ $? -eq 0 ]; then echo \"Installed ansible, running in `pwd`\"; else echo \"Failed to install ansible\"; fi",

#	      "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa",
#	      "if [ $? -eq 0 ]; then echo \"Generated ssh keys pair\"; else echo \"Failed to generate ssh keys pair\"; fi",

#	      "eval \"$(ssh-agent -s)\"",
#	      "ssh-add ~/.ssh/id_rsa",
#	      "ssh-add ./myKey.pem",
#	      "cat \"${tls_private_key.t.private_key_pem}\"", 

#	      "ssh-add \"${tls_private_key.t.private_key_pem}\"",
#	      "echo \"Added SSH key to the ssh-agent\"",

	      "git clone https://github.com/ostasevych/tf-nc.git",
	      "if [ $? -eq 0 ]; then echo \"Successfully cloned git with the configuration\"; else echo \"Failed to clone git\"; fi",

	      "echo \"virtual_host: ${aws_instance.docker-compose.0.public_dns}\" >> ~/tf-nc/playbooks/vars/external_vars.yaml",
	      "echo \"aws_host: s3.${var.region}.amazonaws.com\" >> ~/tf-nc/playbooks/vars/external_vars.yaml",
	      "echo \"aws_bucket: ${var.name_prefix}-nc-data\" >> ~/tf-nc/playbooks/vars/external_vars.yaml",
	      "echo \"aws_region: ${var.region}\" >> ~/tf-nc/playbooks/vars/external_vars.yaml",
	      "echo \"aws_key: ${var.key}\" >> ~/tf-nc/playbooks/vars/external_vars.yaml",
	      "echo \"aws_secret: ${var.secret}\" >> ~/tf-nc/playbooks/vars/external_vars.yaml",
	      "if [ $? -eq 0 ]; then echo \"Public host name and S3 variables have been successfully sent to ansible virtual_host variable at external_vars.yaml\"; else echo \"Failed to store virtual_host and S3 variables at ansible external_vars.yaml \"; fi",

	      "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook ~/tf-nc/playbooks/install_java.yaml",
	      "if [ $? -eq 0 ]; then echo \"Java OpenJDK installed successfully\"; else echo \"Failed to install Java OpenJDK\"; fi",

	      "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook ~/tf-nc/playbooks/install_jenkins.yaml",
	      "if [ $? -eq 0 ]; then echo \"Successfully installed Jenkins, available at http://${self.public_ip}:8080\"; else echo \"Failed to install and/or run Jenkins\"; fi",

	      "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i ${aws_instance.docker-compose.0.private_ip}, --private-key ~/.ssh/${var.PRIVATE_KEY_PATH} -u ${var.ansible_user} ~/tf-nc/playbooks/install_docker-compose.yaml",
	      "if [ $? -eq 0 ]; then echo \"Successfully installed docker-compose at ${aws_instance.docker-compose.0.private_ip}\"; else echo \"Failed to install docker-compose at ${aws_instance.docker-compose.0.private_ip}\"; fi",

	      "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i ${aws_instance.docker-compose.0.private_ip}, --private-key ~/.ssh/${var.PRIVATE_KEY_PATH} -u ${var.ansible_user} ~/tf-nc/playbooks/copy_docker-compose.yaml",
	      "if [ $? -eq 0 ]; then echo \"Successfully copied docker-compose.yaml to ${aws_instance.docker-compose.0.private_ip}\"; else echo \"Failed to copy docker-compose.yaml to ${aws_instance.docker-compose.0.private_ip}\"; fi",

	      "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i ${aws_instance.docker-compose.0.private_ip}, --private-key ~/.ssh/${var.PRIVATE_KEY_PATH} -u ${var.ansible_user} ~/tf-nc/playbooks/service_docker-compose.yaml",
	      "if [ $? -eq 0 ]; then echo \"Successfully created nextcloud.service at ${aws_instance.docker-compose.0.private_ip}\"; else echo \"Failed to add nextcloud.service at ${aws_instance.docker-compose.0.private_ip}\"; fi",

	      "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i ${aws_instance.docker-compose.0.private_ip}, --private-key ~/.ssh/${var.PRIVATE_KEY_PATH} -u ${var.ansible_user} ~/tf-nc/playbooks/up_docker-compose.yaml",
	      "if [ $? -eq 0 ]; then echo \"Successfully started containers at ${aws_instance.docker-compose.0.private_ip}\"; else echo \"Failed to start containers at ${aws_instance.docker-compose.0.private_ip}\"; fi",

	      "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i ${aws_instance.docker-compose.0.private_ip}, --private-key ~/.ssh/${var.PRIVATE_KEY_PATH} -u ${var.ansible_user} ~/tf-nc/playbooks/init_nc.yaml",
	      "if [ $? -eq 0 ]; then echo \"Successfully initialised Nextcloud app! Login: admin / password: r@@t. Change it after logging in!\"; else echo \"Failed to initialise Nextcloud app\"; fi",

]
  }

  tags = {
    Name     = "terraform-ci-${count.index +1 }"
    Location = "Ireland"
  }
}
