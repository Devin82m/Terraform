# SonarQube Homework Assignment
# Devin St. Clair 2017-12

##
# Networking Tasks
##
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "corp" {
  cidr_block           = "10.0.0.0/21"
  tags {
    Name = "Corp VPC"
    Environment = "Corp"
  }
}

resource "aws_internet_gateway" "corp-igw" {
	vpc_id = "${aws_vpc.corp.id}"
  tags {
    Name = "Crop Internet Gateway"
    Envrionment = "Corp"
  }
  depends_on = ["aws_vpc.corp"]
}

resource "aws_subnet" "Corp-Private-1a" {
  vpc_id     = "${aws_vpc.corp.id}"
  cidr_block            = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  tags {
    Name = "Corp Private"
    Environment = "Corp"
  }
}

resource "aws_subnet" "Corp-Private-1b" {
  vpc_id     = "${aws_vpc.corp.id}"
  cidr_block            = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  tags {
    Name = "Corp Private"
    Environment = "Corp"
  }
}

resource "aws_subnet" "Corp-Public-1a" {
  vpc_id     = "${aws_vpc.corp.id}"
  cidr_block            = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  tags {
    Name = "Corp Public"
    Environment = "Corp"
  }
}

resource "aws_route_table" "corp-public-rt" {
	vpc_id = "${aws_vpc.corp.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.corp-igw.id}"
	}
  depends_on = ["aws_internet_gateway.corp-igw",]
}

resource "aws_route_table_association" "corp-public-rta" {
	subnet_id = "${aws_subnet.Corp-Public-1a.id}"
	route_table_id = "${aws_route_table.corp-public-rt.id}"
  depends_on = ["aws_route_table.corp-public-rt"]
}

resource "aws_security_group" "sonarqube-sg" {
  name        = "sonarqube-sg"
  description = "Only corporate traffic to SonarQube"
  vpc_id      = "${aws_vpc.corp.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 9276
      to_port     = 9276
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ingress {
      from_port   = 2879
      to_port     = 2879
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  depends_on = ["aws_subnet.Corp-Private-1a"]
}

##
# RDS Tasks
##
resource "aws_db_subnet_group" "SonarQube-DBSNG" {
  name       = "sonarqube-dbsng"
  subnet_ids = ["${aws_subnet.Corp-Private-1a.id}","${aws_subnet.Corp-Private-1b.id}"]
  depends_on = ["aws_subnet.Corp-Private-1a","aws_subnet.Corp-Private-1a"]
  tags {
    Name = "SonarQube-DB"
    Environment = "Corp"
  }
}

resource "aws_db_parameter_group" "sonarqube-db-pg" {
  name   = "sonarqube-db-pg"
  family = "mysql5.7"
}

resource "aws_db_instance" "sonarqube-db" {
  allocated_storage    = "100"
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7.19"
  instance_class       = "db.m4.large"
  name                 = "sonar"
  username             = "sonarqube"
  password             = "Fd345Bqbzgd43"
  db_subnet_group_name = "sonarqube-dbsng"
  parameter_group_name = "sonarqube-db-pg"
  multi_az = "true"
  backup_retention_period = 7
  maintenance_window = "sun:00:00-sun:01:00"
  storage_encrypted = "true"
  port = "2879"
  depends_on = ["aws_db_subnet_group.SonarQube-DBSNG", "aws_db_parameter_group.sonarqube-db-pg"]
  tags {
    Name = "SonarQube-DB"
    Environment = "Corp"
  }
}

##
# EC2 Tasks
##
resource "aws_instance" "SonarQube-Web" {
  ami = "ami-55ef662f"
  instance_type = "t2.medium"
  subnet_id = "${aws_subnet.Corp-Public-1a.id}"
  disable_api_termination = "true"
  availability_zone = "us-east-1a"
  security_groups = ["${aws_security_group.sonarqube-sg.id}"]
  key_name = "SonarQubeKey"
  monitoring = "true"
  user_data = "${file("sonarqubeinstall.sh")}"
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_size = 100
    volume_type = "gp2"
    #encrypted = "true"
    delete_on_termination = false
  }
  tags {
    Name = "SonarQube"
    Environment = "Corp"
  }
  depends_on = ["aws_db_instance.sonarqube-db", "aws_security_group.sonarqube-sg"]
}

resource "aws_eip" "SonarQube-EIP" {
	instance = "${aws_instance.SonarQube-Web.id}"
	vpc = true
  depends_on = ["aws_instance.SonarQube-Web"]
}