# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Use the first public subnet in the default VPC for the NAT Gateway
data "aws_subnet" "public" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
  availability_zone = "${var.aws_region}a"
} 
