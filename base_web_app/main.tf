/*
This a multiline comment 
This Terraform configuration sets up a basic web application on AWS using an EC2 instance running Nginx.
It includes the necessary networking components such as a VPC, subnet, internet gateway, and security groups.
AWS credentials are required to apply this configuration and can be set using environment variables or the AWS CLI.
*/

#saying we would like to use version 5 of aws provider, terraform will go and find this #
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"              
    }
  }
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  region     = "us-east-1"
}

##################################################################################
# DATA - way to query info from a platform/service. Arguments in data source depend on the type of data. We are querying the data from the AWS provider, we can't make any changes to what we receieve 
##################################################################################

data "aws_ssm_parameter" "amzn2_linux" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
/*
these are all the resources created for networking purposes 
vpc = vnet in azure
*/

resource "aws_vpc" "app" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

}

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id

}

resource "aws_subnet" "public_subnet1" {
  cidr_block              = "10.0.0.0/24"
  vpc_id                  = aws_vpc.app.id
  map_public_ip_on_launch = true
}

# ROUTING #
resource "aws_route_table" "app" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }
}

resource "aws_route_table_association" "app_subnet1" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.app.id
}

# SECURITY GROUPS #
# all the resources for security
# Nginx security group 
resource "aws_security_group" "nginx_sg" {
  name   = "nginx_sg"
  vpc_id = aws_vpc.app.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# INSTANCES #
resource "aws_instance" "nginx1" {
  ami                    = nonsensitive(data.aws_ssm_parameter.amzn2_linux.value)
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet1.id
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]
  user_data_replace_on_change = true

  # Heredoc for user_data — cleanly formatted for Terraform v1.14.6
  user_data = <<-EOF
    #!/bin/bash
    # Install Nginx
    sudo amazon-linux-extras install -y nginx1

    # Start Nginx
    sudo service nginx start

    # Remove default index
    sudo rm -f /usr/share/nginx/html/index.html

    # Write custom HTML
    sudo tee /usr/share/nginx/html/index.html > /dev/null <<WEBSITE
<html>
<head>
  <title>Taco Team Server</title>
</head>
<body style="background-color:#1F778D">
    <p style="text-align: center;">
        <span style="color:#FFFFFF;">
            <span style="font-size:100px;">Welcome to the website! Have a &#127790;</span>
        </span>
    </p>
</body>
</html>
WEBSITE
EOF
}


## above is script that will run when we start an instance for the first time, <<EOF....EOF allows multi line text for user data argument and keeps formatting as you write it #