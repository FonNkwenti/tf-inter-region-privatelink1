data "aws_availability_zones" "main" {
  provider = aws.service_provider_main
}
data "aws_availability_zones" "region" {
  provider = aws.service_provider_region
}
data "aws_caller_identity" "main" {
  provider = aws.service_provider_main
}
data "aws_caller_identity" "region" {
  provider = aws.service_provider_region
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


locals {
  dir_name = basename(path.cwd)
  name     = "${var.project_name}-${var.environment}"

  main_vpc_cidr   = "10.250.0.0/16"
  region_vpc_cidr = "10.150.0.0/16"

  main_azs   = slice(data.aws_availability_zones.main.names, 0, 2)
  region_azs = slice(data.aws_availability_zones.region.names, 0, 2)

  main_az1   = data.aws_availability_zones.main.names[0]
  region_az1 = data.aws_availability_zones.region.names[0]

  main_az2   = data.aws_availability_zones.main.names[1]
  region_az2 = data.aws_availability_zones.region.names[1]

  ami = data.aws_ami.amazon_linux_2.id

  instance_name = "${local.name}-saas"
  vpc_name      = "${local.name}-vpc"
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Service     = var.service_name
    CostCenter  = var.cost_center
  }

}

