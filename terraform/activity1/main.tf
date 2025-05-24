provider "aws" {
    region = "us-east-1"
}
resource "aws_vpc" "activity1-vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "activity1-vpc"
    }
}

resource "aws_subnet" "subneta" {
    vpc_id            = aws_vpc.activity1-vpc.id
    cidr_block        = "10.0.4.0/24"
    availability_zone = "us-east-1a"        
    map_public_ip_on_launch = true
    tags = {
        Name = "subneta"
    }     
}
resource "aws_subnet" "subnetb" {
    vpc_id            = aws_vpc.activity1-vpc.id
    cidr_block        = "10.0.5.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true  
    tags = {
        Name = "subnetb"
    }
}
resource "aws_internet_gateway" "activity1-igw" {
    vpc_id = aws_vpc.activity1-vpc.id

    tags = {
        Name = "activity1-igw"
    }
}
resource "aws_route_table" "activity1-rt" {
    vpc_id = aws_vpc.activity1-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.activity1-igw.id
    }
    tags = {
        Name = "activity1-rt"
    }
}
resource "aws_route_table_association" "public_association_a" {
    subnet_id      = aws_subnet.subneta.id
    route_table_id = aws_route_table.activity1-rt.id
  
}
resource "aws_route_table_association" "public_association_b" {
    subnet_id      = aws_subnet.subnetb.id
    route_table_id = aws_route_table.activity1-rt.id
}
resource "aws_security_group" "activity1-sg_build" {
    vpc_id = aws_vpc.activity1-vpc.id
    name   = "activity1-sg_build"
    description = "Allow SSH access"
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
        Name = "activity1-sg_build"
    }
}
resource "aws_security_group" "tomcat-sg" {
    vpc_id = aws_vpc.activity1-vpc.id
    name   = "tomcat-sg"
    description = "Allow HTTP access"
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
        Name = "tomcat-sg"
    }
}
resource "aws_instance" "activity1-buid_server" {
    ami           = "ami-0e58b56aa4d64231b"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.subneta.id
    vpc_security_group_ids = [aws_security_group.activity1-sg_build.id]
    key_name = "build"
    user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install -y maven
                sudo yum install -y git
                sudo yum install -y java-11*
                cd /home/ec2-user
                sudo git clone https://github.com/JNTGLORY/proj-mdp-152-155.git
                cd /home/ec2-user/proj-mdp-152-155
                sudo -u ec2-user mvn package
                EOF
    tags = {
        Name = "build_server"
    }
}
resource "aws_instance" "activity1-tomcat_server" {
    ami           = "ami-0e58b56aa4d64231b"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.subnetb.id
    vpc_security_group_ids = [aws_security_group.tomcat-sg.id]
    key_name = "build"
    user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install java-1.8.0-openjdk -y
                sudo wget https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.94/bin/apache-tomcat-7.0.94.tar.gz
                sudo tar -xvzf apache-tomcat-7.0.94.tar.gz
                ln -s apache-tomcat-7.0.94 tomcat
                sudo mv apache-tomcat-7.0.94 /opt/tomcat
                chmod +x /opt/tomcat/bin/*.sh
                /opt/tomcat/bin/startup.sh
                EOF
    tags = {
        Name = "tomcat_server"
    }
}


