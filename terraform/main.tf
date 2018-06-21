variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  default = "10.0.0.0/16"
}

variable "key_name" {
  default = "jenkins"
}

resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr_block}"

  tags {
    Name = "Terraform Jenkins"
  }
}

resource "aws_subnet" "vpn_subnet" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = true
  cidr_block              = "${var.subnet_cidr_block}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "Internet Gateway for Jenkins"
  }
}

resource "aws_eip" "jenkins_eip" {
  vpc        = true
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_route" "internet_access_jenkins" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

variable "ssh_user" {
  default = "ec2-user"
}

variable "ssh_port" {
  default = 22
}

variable "ssh_cidr" {
  default = "0.0.0.0/0"
}

variable "https_port" {
  default = 443
}

variable "https_cidr" {
  default = "0.0.0.0/0"
}

variable "tcp_port" {
  default = 8080
}

variable "tcp_cidr" {
  default = "0.0.0.0/0"
}

resource "aws_security_group" "sg" {
  name        = "jenkins_sg"
  description = "Allow traffic needed by Jenkins"
  vpc_id      = "${aws_vpc.vpc.id}"

  // ssh
  ingress {
    from_port   = "${var.ssh_port}"
    to_port     = "${var.ssh_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_cidr}"]
  }

  // https
  ingress {
    from_port   = "${var.https_port}"
    to_port     = "${var.https_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.https_cidr}"]
  }

  // Jenkins tcp
  ingress {
    from_port   = "${var.tcp_port}"
    to_port     = "${var.tcp_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.tcp_cidr}"]
  }

  // all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "ami" {
  default = "ami-ff89dc80"
}

variable "instance_type" {
  default = "t2.micro"
}

resource "aws_instance" "jenkins" {
  tags {
    Name = "jenkins"
  }

  ami                         = "${var.ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  subnet_id                   = "${aws_subnet.vpn_subnet.id}"
  vpc_security_group_ids      = ["${aws_security_group.sg.id}"]
  associate_public_ip_address = true
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.jenkins.id}"
  allocation_id = "${aws_eip.jenkins_eip.id}"
}
