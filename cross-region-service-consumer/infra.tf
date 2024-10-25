

////////////////////////////

module "service_consumer_main" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.main_vpc_cidr

  azs             = local.main_azs
  public_subnets  = [for k, v in local.main_azs : cidrsubnet(local.main_vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.main_azs : cidrsubnet(local.main_vpc_cidr, 8, k + 10)]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-vpc"
  })

  providers = {
    aws = aws.service_consumer_main
  }
}

# 
resource "aws_ec2_transit_gateway" "main_tgw" {
  description = "Main region Transit Gateway"

  tags = merge(local.common_tags, {
    Name = "main-region-tgw"
  })
  provider = aws.service_consumer_main
}

resource "aws_route" "transit_vpc_cidr_to_main_tgw" {
  count                  = length(module.service_consumer_main.private_route_table_ids)
  route_table_id         = element(module.service_consumer_main.private_route_table_ids, count.index)
  destination_cidr_block = local.transit_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main_tgw.id

  provider = aws.service_consumer_main
}

# attach service_provide_main VPC to transit gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "main_tgw_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id
  vpc_id             = module.service_consumer_main.vpc_id
  subnet_ids         = module.service_consumer_main.private_subnets

  tags = merge(local.common_tags, {
    Name = "service-consumer-main-vpc"
  })
  provider = aws.service_consumer_main
}



data "aws_ec2_transit_gateway_route_table" "main_tgw_default_route_table" {
  filter {
    name   = "default-association-route-table"
    values = ["true"]
  }

  # transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id

  depends_on = [aws_ec2_transit_gateway.main_tgw]

  provider = aws.service_consumer_main
}


////////////////////////////////////////////////////////////




## TGW PEERING


# create a transit gateway peering attachment
resource "aws_ec2_transit_gateway_peering_attachment" "main_to_transit_peering" {
  peer_region             = var.transit_region
  transit_gateway_id      = aws_ec2_transit_gateway.main_tgw.id
  peer_transit_gateway_id = aws_ec2_transit_gateway.transit_tgw.id

  tags = merge(local.common_tags, {
    Name = "tgw-peering-main-to-transit"
    Side = "Requester"
  })
  provider = aws.service_consumer_main
}



resource "aws_ec2_transit_gateway_route" "main_to_transit_route" {
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.main_tgw_default_route_table.id
  destination_cidr_block        = local.transit_vpc_cidr
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.main_to_transit_peering.id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment.main_to_transit_peering,
    aws_ec2_transit_gateway_vpc_attachment.main_tgw_attachment,
    aws_ec2_transit_gateway_peering_attachment_accepter.transit_accept_main
  ]

  provider = aws.service_consumer_main
}






/////////

resource "aws_vpc_endpoint" "ssm_ep" {
  for_each = local.ssm_services
  vpc_id   = module.service_consumer_main.vpc_id
  ip_address_type     = "ipv4"
  vpc_endpoint_type   = "Interface"

  service_name        = each.value.name
  security_group_ids  = [aws_security_group.ssm.id]
  private_dns_enabled = true
  subnet_ids          = module.service_consumer_main.private_subnets

  tags = merge(local.common_tags, {
    Name = "main-ssm-endpoint"
  })

  provider = aws.service_consumer_main
}

resource "aws_security_group" "ssm" {
  name        = "allow-ssm"
  description = "Allow traffic to SSM endpoint"
  vpc_id      = module.service_consumer_main.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # cidr_blocks = [aws_subnet.pri_sn1_az1.cidr_block]
    # cidr_blocks = module.service_consumer_main.private_subnets_cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    lifecycle {
    create_before_destroy = true
  }
  provider = aws.service_consumer_main
}

resource "aws_security_group" "ssm_client" {
  name        = "ssm-client"
  description = "allow traffic from SSM Session maanger"
  vpc_id      = module.service_consumer_main.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    # cidr_blocks = module.service_consumer_main.private_subnets_cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags,{
    Name = "ssm-client"
  })
    lifecycle {
    create_before_destroy = true
  }
  provider = aws.service_consumer_main
}
