# Create a security group named 'customer-securitygrp' with ingress rules
resource "aws_security_group" "ec2-webapp-sg80" {
  vpc_id = aws_vpc.WEB_APP_VPC.id
  /*
  tags = {
    Name = "Webapp-sg"
  } 
  */

  # Allow HTTP access from anywhere for testing (consider restricting later)
  ingress {
    description = "MyHomePage"
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  # Allow all outbound traffic for simplicity (consider restricting later)
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name    = "ec2-webapp-sg80"
    # Name: "${var.env_prefix}-sg-80"
    Service = "web-application"
    Owner   = "Balactus"
    Planet  = "Taa"
  }

}

#latest image  
data "aws_ami" "latest-amazon-linux-image-webapp" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = [var.image_name]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}


# Launch the EC2 instance
resource "aws_instance" "ec2-webapp" {
  ami = data.aws_ami.latest-amazon-linux-image-webapp.id
  # ami = ami-023ff3d4ab11b2525

  #instance_type = var.instance_type[0]
  instance_type = "t2.micro"  # Adjust instance type as needed

  # Enable auto-assign public IP (optional)
  associate_public_ip_address = true
    
  # availability_zone = var.avail_zone

  # Ensure you have a key pair or key name created in the region
  key_name = "MyLinuxBox"
  # key_name = var.key_name

 # Securely encode the user data script with base64encode
 user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd

    # Get the IMDSv2 token
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

    # Background the curl requests
    curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4 &> /tmp/local_ipv4 &
    curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone &> /tmp/az &
    curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ &> /tmp/macid &
    wait

    macid=$(cat /tmp/macid)
    local_ipv4=$(cat /tmp/local_ipv4)
    az=$(cat /tmp/az)
    vpc=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$macid/vpc-id)

    # Create HTML file
    cat <<-HTML > /var/www/html/index.html
    <!doctype html>
    <html lang="en" class="h-100">
    <head>
    <title>Details for EC2 instance</title>
    </head>
    <body>
    <div>
    <h1>Balactus has Arrived in Tokyo</h1>
    <h1>Keisha World has been consumed</h1>
    <p><b>Instance Name:</b> $(hostname -f) </p>
    <p><b>Instance Private Ip Address: </b> $local_ipv4</p>
    <p><b>Availability Zone: </b> $az</p>
    <p><b>Virtual Private Cloud (VPC):</b> $vpc</p>
    </div>
    </body>
    </html>
    HTML

    # Clean up the temp files
    rm -f /tmp/local_ipv4 /tmp/az /tmp/macid
  EOF
  )

  tags = {
     #Name: "${var.env_prefix}-server"
     Name    = "ec2-webapp"
     Service = "web-application1"
     Owner   = "Blackneto"
     Planet  = "Taa"
  }

  # Associate the instance with a security group
  vpc_security_group_ids = [aws_security_group.ec2-webapp-sg80.id]

  # Associate the instance with a subnet
  subnet_id = aws_subnet.WEB_APP_SUBNET.id  
  

  lifecycle {
    create_before_destroy = true
  }
}


# Output the public IP address of the instance (optional)
output "webapp_public_ip" {
  value = aws_instance.ec2-webapp.public_ip
}
