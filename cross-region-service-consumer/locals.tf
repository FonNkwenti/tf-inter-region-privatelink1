data "aws_availability_zones" "main" {
  provider = aws.service_consumer_main
}
data "aws_availability_zones" "transit" {
  provider = aws.service_consumer_transit
}
data "aws_caller_identity" "main" {
  provider = aws.service_consumer_main
}
data "aws_caller_identity" "transit" {
  provider = aws.service_consumer_transit
}

data "aws_ami" "amazon_linux_2_main" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  provider = aws.service_consumer_main
}
data "aws_ami" "amazon_linux_2_transit" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  provider = aws.service_consumer_transit
}


locals {
  dir_name = basename(path.cwd)
  name     = "${var.project_name}-${var.environment}"

  main_vpc_cidr   = "10.10.0.0/16"
  transit_vpc_cidr = "10.15.0.0/16"

  main_azs   = slice(data.aws_availability_zones.main.names, 0, 2)
  transit_azs = slice(data.aws_availability_zones.transit.names, 0, 2)

  main_az1   = data.aws_availability_zones.main.names[0]
  transit_az1 = data.aws_availability_zones.transit.names[0]

  main_az2   = data.aws_availability_zones.main.names[1]
  transit_az2 = data.aws_availability_zones.transit.names[1]

  main_ami   = data.aws_ami.amazon_linux_2_main.id
  transit_ami = data.aws_ami.amazon_linux_2_transit.id

  instance_name = "${local.name}-saas"
  vpc_name      = "${local.name}-vpc"

    common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Service     = var.service_name
    CostCenter  = var.cost_center
  }

  ssm_services = {
  "ec2messages" : {
    "name" : "com.amazonaws.${var.main_region}.ec2messages"
  },
  "ssm" : {
    "name" : "com.amazonaws.${var.main_region}.ssm"
  },
  "ssmmessages" : {
    "name" : "com.amazonaws.${var.main_region}.ssmmessages"
  }
}

}
