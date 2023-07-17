# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create EC2 Instance
resource "aws_instance" "jenkins_instance" {
  ami                    = "ami-04a0ae173da5807d3"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg_jenkins.id]

  tags = {
    Name = "jenkins_instance"
  }

  # BOOTSTRAP EC2 INSTANCE TO INSTALL AND THEN START JENKINS
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo yum upgrade
    sudo amazon-linux-extras install java-openjdk11 -y
    sudo dnf install java-11-amazon-corretto -y
    sudo yum install jenkins -y
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
  EOF
}


# Create and assign a security group to the Jenkins EC2 instance
resource "aws_security_group" "sg_jenkins" {
  name_prefix = "sg_jenkins"

  # Allow incoming TCP on port 22
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow incoming TCP on port 8080
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow incoming TCP requests on port 443 HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Allow outbound
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "sg_jenkins"
  }
}

# Create an S3 bucket for Jenkins artifacts
resource "aws_s3_bucket" "jenkins_artifacts" {
  bucket = "jenkins-artifacts-${random_id.randomness.hex}"

  tags = {
    Name = "jenkins_artifacts"
  }
}

# Create private the S3 bucket so no public access
resource "aws_s3_bucket_acl" "private_jenkins_bucket" {
  bucket = aws_s3_bucket.jenkins_artifacts.id
  acl    = "private"
}

# Create random number name  for S3 bucket name
resource "random_id" "randomness" {
  byte_length = 4
}
