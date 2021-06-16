variable "profile" {
  default = "terraform"
}

variable "region" {
  default = "eu-west-1"
}

variable "instance" {
  default = "t2.micro"
}

variable "instance_count" {
  default = "1"
}

variable "public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "PUBLIC_KEY_PATH" {
#  default = "my-key-pair.pub"
default = "myKey.pub"
}

variable "PRIVATE_KEY_PATH" {
#  default = "my-key-pair"
default = "myKey.pem"
}

#variable "public_key" {
#  default = "~/.ssh/id_rsa.pub"
#}

#variable "private_key" {
#  default = "~/.ssh/terraform.pem"
#}

variable "ansible_user" {
  default = "ubuntu"
}

variable "connection_type" {
  default = "ssh"
}

variable "amis" {
  type = map(string)

  default = {
    eu-west-1 = "ami-0a8e758f5e873d1c1" # Ireland
    eu-central-1 = "ami-05f7491af5eef733a" # Frankfurt
    eu-north-1 = "ami-0ff338189efb7ed37" # Stockholm
  }
}

variable "ami" {
  default = "ami-0a8e758f5e873d1c1"
}

variable "az" {
  default = {
    "0" = "eu-west-1a"
    "1" = "eu-west-1b"
    "2" = "eu-west-1c"
  }
}


variable "private_ips" {
  default = {
    "0" = "10.0.0.100"
    "1" = "10.0.0.101"
//    "2" = "10.0.0.102"
  }
}
