provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "activity1_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "activity1-vpc"
  }
}

# Subnet
resource "aws_subnet" "subneta" {
  vpc_id                  = aws_vpc.activity1_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "subneta"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "activity1_igw" {
  vpc_id = aws_vpc.activity1_vpc.id
  tags = {
    Name = "activity1-igw"
  }
}

# Route Table
resource "aws_route_table" "activity1_rt" {
  vpc_id = aws_vpc.activity1_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.activity1_igw.id
  }

  tags = {
    Name = "activity1-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "activity1_rt_assoc" {
  subnet_id      = aws_subnet.subneta.id
  route_table_id = aws_route_table.activity1_rt.id
}

# Security Group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  vpc_id      = aws_vpc.activity1_vpc.id
  name        = "jenkins-sg"
  description = "Allow HTTP (8080) and SSH (22)"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

# EC2 Instance - Jenkins on Ubuntu
resource "aws_instance" "jenkins_server" {
  ami                         = "ami-0731becbf832f281e" # Ubuntu 22.04 LTS (for us-east-1)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subneta.id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true
  key_name                    = "great" # Replace with your actual key pair name

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y fontconfig openjdk-17-jre wget gnupg2 curl

              # Jenkins key and repo
              mkdir -p /etc/apt/keyrings
              wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian/jenkins.io-2023.key
              echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" > /etc/apt/sources.list.d/jenkins.list

              apt update -y
              apt install -y jenkins

              systemctl enable jenkins
              systemctl start jenkins
  EOF

  tags = {
    Name = "jenkins_server"
  }
}

# Outputs
output "jenkins_instance_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "vpc_id" {
  value = aws_vpc.activity1_vpc.id
}
