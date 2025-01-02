resource "aws_ec2_transit_gateway" "tokyo-tgw" {
  description = "tg-backend-database"
  tags = {
    Name = "Backend-Database Transit Gateway"
  }
}
