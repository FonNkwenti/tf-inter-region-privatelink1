
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.2.1"

  name                        = "${local.name}-client"
  instance_type               = "t2.micro"
  monitoring                  = false
  associate_public_ip_address = false
  key_name                    = var.ssh_key_pair
  subnet_id                   = module.service_consumer_main.private_subnets[0]
  vpc_security_group_ids      = [module.instance_security_group.security_group_id]

  providers = {
    aws = aws.service_consumer_main
  }
}


module "instance_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "privatelink-client-sg"
  vpc_id      = module.service_consumer_main.vpc_id
  description = "private instance security group"

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "allow ssh"
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = "0.0.0.0/0"
      description = "allow icmp pings"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
    providers = {
    aws = aws.service_consumer_main
  }
}










# resource "aws_instance" "privateLink_consumer" {
#   ami                    = local.main_ami
#   instance_type          = "t2.micro"
#   subnet_id              = element(module.service_consumer_main.private_subnets, 0)
#   associate_public_ip_address = false
#   key_name = var.ssh_key_pair
#   vpc_security_group_ids = [aws_security_group.ssm_client.id]


#   tags = merge(local.common_tags, {
#     Name = "main-test-instance"
#     # Name = local.instance_name
#   })

#   provider = aws.service_consumer_main
# }




# // transit ec2 instance
# resource "aws_instance" "transit_consumer" {
#   ami                    = local.transit_ami
#   instance_type          = "t2.micro"
#   subnet_id              = element(module.service_consumer_transit.private_subnets, 0)
#   associate_public_ip_address = false
#   vpc_security_group_ids = [aws_security_group.transit_icmp.id]
 

#   tags = merge(local.common_tags, {
#     Name = local.instance_name
#   })

#   provider = aws.service_consumer_transit
# }


# resource "aws_security_group" "transit_icmp" {
#   name        = "transit-test-instance"
#   description = "Allow ICMP pings for tests"
#   vpc_id      = module.service_consumer_transit.vpc_id

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
#     Name = "transit-test-instance"
#   })
#   provider = aws.service_consumer_transit
# }

