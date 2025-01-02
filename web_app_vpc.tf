resource "aws_vpc" "WEB_APP_VPC" {              # VPC ID: aws_vpc.WEB_APP_VPC.id  
  cidr_block       = "10.240.0.0/16"
  

  tags = {
    Name = "WEB_APP_VPC"
  }
}

resource "aws_subnet" "WEB_APP_SUBNET" {
  vpc_id     = aws_vpc.WEB_APP_VPC.id 
  cidr_block = "10.240.0.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "WEB_APP_SUBNET"
  }
}

resource "aws_internet_gateway" "WEB_APP_IGW" {     # Internet Gateway ID: aws_internet_gateway.WEB_APP_IGW.id
  vpc_id     = aws_vpc.WEB_APP_VPC.id

  tags = {
    Name = "WEB_APP_IGW"
  }
}

resource "aws_default_route_table" "WEB_APP_ROUTE" {    # Route Table ID: aws_default_route_table.WEB_APP_ROUTE.id
  default_route_table_id = aws_vpc.WEB_APP_VPC.default_route_table_id

  tags = {
    Name = "WEB_APP_ROUTE"
  }
}

resource "aws_route" "web_app_route" {
  route_table_id         = aws_default_route_table.WEB_APP_ROUTE.id
  destination_cidr_block = "0.0.0.0/0"    # Route all traffic to the Internet Gateway
  gateway_id             = aws_internet_gateway.WEB_APP_IGW.id

  depends_on = [aws_vpc.WEB_APP_VPC]  # Ensure VPC is created before route
}


/* TRANSIT GATEWAY ATTACHMENT */
# Route to BACKEND_SERVICES_VPC via Transit Gateway Attachment
resource "aws_route" "web_app_to_backend_services" {
  route_table_id         = aws_default_route_table.WEB_APP_ROUTE.id
  destination_cidr_block = "10.241.0.0/16"  # Replace with actual VPC2 CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.web_app_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.web_app_attachment]
}


# Route to SHARED_DATABASE_VPC via Transit Gateway Attachment
resource "aws_route" "web_app_to_shared_database" {
  route_table_id         = aws_default_route_table.WEB_APP_ROUTE.id
  destination_cidr_block = "10.242.0.0/16"  # Replace with actual VPC3 CIDR block
  transit_gateway_id     = aws_ec2_transit_gateway_vpc_attachment.web_app_attachment.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.web_app_attachment]
}
