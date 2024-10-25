
module "service_consumer_transit" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-transit"
  cidr = local.transit_vpc_cidr

  azs             = local.transit_azs
  private_subnets = [for k, v in local.transit_azs : cidrsubnet(local.transit_vpc_cidr, 8, k + 10)]

  # enable_nat_gateway = true
  # single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-transit"
  })

  providers = {
    aws = aws.service_consumer_transit
  }
}

resource "aws_ec2_transit_gateway" "transit_tgw" {
  description = "Main region Transit Gateway"

  tags = merge(local.common_tags, {
    Name = "transit-region-tgw"
  })
  provider = aws.service_consumer_transit
}

resource "aws_route" "main_vpc_cidr_to_transit_tgw" {
  count                  = length(module.service_consumer_transit.private_route_table_ids)
  route_table_id         = element(module.service_consumer_transit.private_route_table_ids, count.index)
  destination_cidr_block = local.main_vpc_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.transit_tgw.id

  provider = aws.service_consumer_transit
}

# attach service_provide_transit VPC to transit gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "transit_tgw_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.transit_tgw.id
  vpc_id             = module.service_consumer_transit.vpc_id
  subnet_ids         = module.service_consumer_transit.private_subnets

  tags = merge(local.common_tags, {
    Name = "service-consumer-transit-vpc"
  })
  provider = aws.service_consumer_transit
}

data "aws_ec2_transit_gateway_route_table" "transit_tgw_default_route_table" {
  filter {
    name   = "default-association-route-table"
    values = ["true"]
  }

  depends_on = [aws_ec2_transit_gateway.transit_tgw]

  provider = aws.service_consumer_transit
}

## TGW PEERING

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "transit_accept_main" {
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.accepter_peering_data.id

  tags = merge(local.common_tags, {
    Name = "tgw-peering-transit-to-main"
    Side = "Acceptor"
  })
  provider = aws.service_consumer_transit


}

# # Transit VPC transit Gateway's peering request needs to be accepted.
# So, we fetch the Peering Attachment.
data "aws_ec2_transit_gateway_peering_attachment" "accepter_peering_data" {
  depends_on = [aws_ec2_transit_gateway_peering_attachment.main_to_transit_peering]
  filter {
    name   = "state"
    values = ["pendingAcceptance", "available"]
  }
  filter {
    name = "transit-gateway-id"
    values = [aws_ec2_transit_gateway.transit_tgw.id]
  }
  provider = aws.service_consumer_transit
}

resource "aws_ec2_transit_gateway_route" "transit_to_main_route" {
  transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.transit_tgw_default_route_table.id
  destination_cidr_block        = local.main_vpc_cidr
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.accepter_peering_data.id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment.main_to_transit_peering,
    aws_ec2_transit_gateway_vpc_attachment.transit_tgw_attachment,
    aws_ec2_transit_gateway_peering_attachment_accepter.transit_accept_main,
  ]

  provider = aws.service_consumer_transit
}



# resource "aws_vpc_endpoint" "privateLink_service" {
#   vpc_endpoint_type   = "Interface"
#   private_dns_enabled = false
#   vpc_id              = aws_vpc.this.id
#   service_name        = var.privateLink_service_name
#   security_group_ids  = [aws_security_group.privateLink_service.id]
#   subnet_ids          = [aws_subnet.pri_sn1_az1.id]

#   tags = merge(local.common_tags,{
#     Name = "privateLink-service"
#   })
#   provider = aws.service_consumer_transit
# }

# resource "aws_security_group" "privateLink_service" {
#   name        = "privateLink-service"
#   description = "Security group for privateLink Interface Endpoint"
#   vpc_id      = aws_vpc.this.id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]

#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(local.common_tags,{
#     Name = "privateLink-service"
#   })

#   lifecycle {
#     create_before_destroy = true
#   }
#   provider = aws.service_consumer_transit
# }