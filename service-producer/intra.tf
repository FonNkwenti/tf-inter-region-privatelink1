
# module "service_provider_main_2" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 5.0"

#   name = "${local.name}-main-2"
#   cidr = "10.10.0.0/16"

#   azs             = local.main_azs
#   private_subnets = [for k, v in local.main_azs : cidrsubnet("10.10.0.0/16", 8, k + 10)]

#   # enable_nat_gateway = true
#   # single_nat_gateway = true

#   enable_dns_hostnames = true
#   enable_dns_support   = true

#   tags = merge(local.common_tags, {
#     Name = "${local.name}-main-2"
#   })

#   providers = {
#     aws = aws.service_provider_main
#   }
# }

# resource "aws_route" "private_static_route_to_tgw" {
#   count                  = length(module.service_provider_main.private_route_table_ids)
#   route_table_id         = element(module.service_provider_main.private_route_table_ids, count.index)
#   destination_cidr_block = "10.10.0.0/16"                       
#   transit_gateway_id     = aws_ec2_transit_gateway.main_tgw.id 
#   provider = aws.service_provider_main
# }

# resource "aws_route" "main_to_main_2_tgw" {
#   count                  = length(module.service_provider_main_2.private_route_table_ids)
#   route_table_id         = element(module.service_provider_main_2.private_route_table_ids, count.index)
#   destination_cidr_block = local.main_vpc_cidr
#   transit_gateway_id     = aws_ec2_transit_gateway.main_tgw.id

#   provider = aws.service_provider_main
# }

# resource "aws_ec2_transit_gateway_vpc_attachment" "main_2_tgw_attachment" {
#   transit_gateway_id = aws_ec2_transit_gateway.main_tgw.id
#   vpc_id             = module.service_provider_main_2.vpc_id
#   subnet_ids         = module.service_provider_main_2.private_subnets

#   tags = merge(local.common_tags, {
#     Name = "main-2-vpc"
#   })
#   provider = aws.service_provider_main
# }


# resource "aws_ec2_transit_gateway_route" "main_tgw_route_to_service_provider_main_2" {
#   transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.main_tgw_default_route_table.id
#   destination_cidr_block         = "10.10.0.0/16"
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main_2_tgw_attachment.id

#   provider = aws.service_provider_main
# }


# resource "aws_ec2_transit_gateway_route" "main_2_to_main_route" {
#   transit_gateway_route_table_id = data.aws_ec2_transit_gateway_route_table.main_tgw_default_route_table.id
#   destination_cidr_block         = local.main_vpc_cidr # CIDR of service_provider_main
#   transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.main_tgw_attachment.id

#   provider = aws.service_provider_main
# }



# /////////////////
# resource "aws_instance" "main_2_test" {
#   ami           = local.main_ami
#   instance_type = "t2.micro"
#   subnet_id     = element(module.service_provider_main_2.private_subnets, 0)
#   #   subnet_id              = aws_subnet.pri_sn1_az1.id
#   associate_public_ip_address = false
#   #   key_name                    = "default-euw1"
#   vpc_security_group_ids = [aws_security_group.main_2_icmp.id]
#   iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

#   tags = merge(local.common_tags, {
#     Name = "main-2"
#   })

#   provider = aws.service_provider_main
# }


# resource "aws_security_group" "main_2_icmp" {
#   name        = "main-2-test-instance"
#   description = "Allow ICMP pings for tests"
#   vpc_id      = module.service_provider_main_2.vpc_id

#   ingress {
#     from_port   = 8
#     to_port     = 0
#     protocol    = "icmp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "TCP"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(local.common_tags, {
#     Name = "main-2-test-instance"
#   })
#   provider = aws.service_provider_main
# }


