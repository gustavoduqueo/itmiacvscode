############# VPC ##############

resource "aws_vpc" "VPCITMIaCVSCode" {
  cidr_block = "${var.vpc_cidr}"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "VPCITMIaCVSCode"
  }
}

############# Subnets #############

resource "aws_subnet" "SUBNET_ITMIaC_1_VSCode" {
  vpc_id = aws_vpc.VPCITMIaCVSCode.id
  cidr_block = "${var.subnet_1_cidr}"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "SUBNET_ITMIaC_1_VSCode"
    "Env" = "LAB"
  }
  depends_on = [
    aws_vpc.VPCITMIaCVSCode
  ]
}

resource "aws_subnet" "SUBNET_ITMIaC_2_VSCode" {
  vpc_id = aws_vpc.VPCITMIaCVSCode.id
  cidr_block = "${var.subnet_2_cidr}"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "SUBNET_ITMIaC_1_VSCode"
    "Env" = "LAB"
  }
  depends_on = [
    aws_vpc.VPCITMIaCVSCode
  ]
}

############# Internet Gateway #############

resource "aws_internet_gateway" "IG_ITMIac_VSCode" {
  vpc_id = aws_vpc.VPCITMIaCVSCode.id
}

############# Route Table #############

resource "aws_route_table" "RT_ITMIaC_VSCode" {
  vpc_id = aws_vpc.VPCITMIaCVSCode.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IG_ITMIac_VSCode.id
  }
 depends_on = [aws_internet_gateway.IG_ITMIac_VSCode]
}

resource "aws_main_route_table_association" "RT_AssociationJoomla" {
  route_table_id = aws_route_table.RT_ITMIaC_VSCode.id
  vpc_id         = aws_vpc.VPCITMIaCVSCode.id
}

############# EC2 Security Group #############

resource "aws_security_group" "SG_JoomlaITMIaC_VSCode" {
  name = "SG_JoomlaITMIaC_IntelliJ"
  vpc_id = aws_vpc.VPCITMIaCVSCode.id
  ingress {
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############# RDS Subnet Group #############

resource "aws_db_subnet_group" "SNG_Joomla_VSCode" {
  name = "${var.rds_db_subnet_group_name}"
  subnet_ids = [aws_subnet.SUBNET_ITMIaC_1_VSCode.id,aws_subnet.SUBNET_ITMIaC_2_VSCode.id]
}

############# RDS MySQL #############

resource "aws_db_instance" "RDS_Joomla_VSCode" {
  identifier           = "${var.rds_identifier}"
  allocated_storage    = "${var.rds_allocated_storage}"
  name              = "${var.rds_db_name}"
  engine               = "${var.rds_engine}"
  engine_version       = "${var.rds_engine_version}"
  instance_class       = "${var.rds_instance_class}"
  username             = "${var.rds_username}"
  password             = "${var.rds_password}"
  db_subnet_group_name = aws_db_subnet_group.SNG_Joomla_VSCode.name
  vpc_security_group_ids = [aws_security_group.SG_JoomlaITMIaC_VSCode.id]
  multi_az             = "${var.rds_multi_az}"
  publicly_accessible  = "${var.rds_publicly_accessible}"
  skip_final_snapshot  = true
}

############# EC2 Joomla Instance #############

resource "aws_instance" "EC2_Joomla_Lab_1_VSCode" {
  ami = "${var.ec2_joomla_ami}"
  instance_type = "${var.ec2_joomla_instance_type}"
  count = "${var.ec2_joomla_instance_quantity}"
  subnet_id = aws_subnet.SUBNET_ITMIaC_1_VSCode.id
  key_name = "${var.aws_keypair}"
  security_groups = [aws_security_group.SG_JoomlaITMIaC_VSCode.id]
  tags = {
    Name = "${var.ec2_joomla_instance_name}"
  }
  user_data = <<EOF
#!/bin/bash
yum install -y httpd httpd-tools mod_ssl
systemctl start httpd
systemctl enable httpd
amazon-linux-extras enable php8.1
yum clean metadata
yum install -y php php-common php-pear
yum install -y php-{cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip}
mkdir /var/www/html/joomla
cd /var/www/html/joomla
wget https://downloads.joomla.org/cms/joomla4/4-3-0/Joomla_4-3-0-Stable-Full_Package.zip
unzip Joomla_4-3-0-Stable-Full_Package.zip
sudo cp /var/www/html/joomla/htaccess.txt /var/www/html/joomla/.htaccess
chown -R apache:apache /var/www/html/joomla
chmod -R 755 /var/www/html/joomla
chmod -R 777 /var/www/
systemctl restart httpd
EOF
}