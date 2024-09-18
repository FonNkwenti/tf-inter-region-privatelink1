#######################################################
##  setup VPCs: service_provider_main 
#######################################################

module "service_provider_main" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.main_vpc_cidr

  azs             = local.main_azs
  public_subnets  = [for k, v in local.main_azs : cidrsubnet(local.main_vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.main_azs : cidrsubnet(local.main_vpc_cidr, 8, k + 10)]

  # enable_nat_gateway = true
  # single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-vpc"
  })

  providers = {
    aws = aws.service_provider_main
  }
}


#######################################################
##  setup VPCs: service_provider_region 
#######################################################

module "service_provider_region" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  # name = "${local.name}-region"
  name = local.name
  cidr = local.region_vpc_cidr

  azs = local.region_azs
  # public_subnets  = [for k, v in local.azs : cidrsubnet(local.region_vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.region_azs : cidrsubnet(local.region_vpc_cidr, 8, k + 10)]

  enable_nat_gateway = false
  single_nat_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-vpc"
  })

  providers = {
    aws = aws.service_provider_region
  }
}




#######################################################
##  setup Transit Gateway and Peering
#######################################################
resource "aws_ec2_transit_gateway" "main_tgw" {
  description = "Transit Gateway for application region"

  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = merge(local.common_tags, {
    Name = "main-tgw"
  })
  provider = aws.service_provider_main
}
# attach service_provide_main VPC to transit gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "main_tgw_attachment" {
  transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id
  vpc_id             = module.service_provider_main.vpc_id
  subnet_ids         = module.service_provider_main.private_subnets

  tags = merge(local.common_tags, {
    Name = "service-provider-main-vpc"
  })
  provider = aws.service_provider_main
}

////////////////////////////////////////////////////////////

# resource "aws_ec2_transit_gateway" "region_tgw" {
#   description = "Transit Gateway for region"

#   default_route_table_association = "disable"
#   default_route_table_propagation = "disable"

#   tags = merge(local.common_tags, {
#     Name = "region-tgw"
#   })
#   provider = aws.service_provider_region
# }

# resource "aws_ec2_transit_gateway_vpc_attachment" "region_tgw_attachment" {
#   transit_gateway_id = aws_ec2_transit_gateway.region_tgw.id
#   vpc_id             = module.service_provider_region.vpc_id
#   subnet_ids         = module.service_provider_region.private_subnets

#   tags = merge(local.common_tags, {
#     Name = "service-provider-region-vpc"
#   })
#   provider = aws.service_provider_region
# }


# # create a transit gateway peering attachment
# resource "aws_ec2_transit_gateway_peering_attachment" "main_region_peering" {
#   peer_region             = var.region_1
#   transit_gateway_id      = aws_ec2_transit_gateway.main_tgw.id
#   peer_transit_gateway_id = aws_ec2_transit_gateway.region_tgw.id

#   tags = merge(local.common_tags, {
#     Name = "tgw-peering-requester"
#     Side = "Requester"
#   })
#   provider = aws.service_provider_main
# }

# # Transit Gateway 2's peering request needs to be accepted.
# # So, we fetch the Peering Attachment that is created for the Gateway 2.
# data "aws_ec2_transit_gateway_peering_attachment" "accepter_peering_data" {
#   depends_on = [aws_ec2_transit_gateway_peering_attachment.main_region_peering]
#   filter {
#     name   = "state"
#     values = ["pendingAcceptance"] # Ensures only attachments pending acceptance are fetched
#   }
#   filter {
#     name   = "transit-gateway-id"
#     values = [aws_ec2_transit_gateway.region_tgw.id] # Fetching the correct transit gateway
#   }
#   provider = aws.service_provider_region
# }

# # accept the peering request from main
# resource "aws_ec2_transit_gateway_peering_attachment_accepter" "region_1_accepter" {
#   transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.accepter_peering_data.id

#   tags = merge(local.common_tags, {
#     Name = "tgw-peering-accepter"
#     Side = "Acceptor"
#   })
#   provider = aws.service_provider_region
# }