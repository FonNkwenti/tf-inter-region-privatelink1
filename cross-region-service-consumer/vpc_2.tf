#######################################################
##  Cross Account Service Consumer Infrastructure 
#######################################################

resource "aws_vpc" "vpc_2" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${local.name}-vpc"
  })
  provider = aws.service_consumer_main
}


resource "aws_subnet" "pri_sn1_az1_2" {
  vpc_id     = aws_vpc.vpc_2.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 0)
  availability_zone       = local.main_az1
  tags = merge(local.common_tags, {
    Name = "pri-sn1-az1"
  })
    lifecycle {
    create_before_destroy = true
  }
  provider = aws.service_consumer_main
}

resource "aws_route_table" "pri_rt1_az1_2" {
  vpc_id = aws_vpc.vpc_2.id

  tags = merge(local.common_tags ,{
    Name    = "pri-rt1-az1-2"
  })
  provider = aws.service_consumer_main
}

resource "aws_route_table_association" "pri_rta1_az2_2" {
  subnet_id      = aws_subnet.pri_sn1_az1_2.id
  route_table_id = aws_route_table.pri_rt1_az1_2.id
  
  provider = aws.service_consumer_main
}



resource "aws_vpc_endpoint" "ssm_ep_2" {
  for_each = local.ssm_services
  vpc_id   = aws_vpc.vpc_2.id
  ip_address_type     = "ipv4"
  vpc_endpoint_type   = "Interface"

  service_name        = each.value.name
  security_group_ids  = [aws_security_group.ssm_2.id]
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.pri_sn1_az1_2.id]

  provider = aws.service_consumer_main
}



resource "aws_security_group" "ssm_2" {
  name        = "allow-ssm-2"
  description = "Allow traffic to SSM endpoint"
  vpc_id      = aws_vpc.vpc_2.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.pri_sn1_az1_2.cidr_block]
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

resource "aws_security_group" "ssm_client_2" {
  name        = "ssm-client-2"
  description = "allow traffic from SSM Session maanger"
  vpc_id      = aws_vpc.vpc_2.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = [aws_subnet.pri_sn1_az1_2.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.common_tags,{
    Name = "ssm-client-2"
  })
    lifecycle {
    create_before_destroy = true
  }

  provider = aws.service_consumer_main
}

resource "aws_instance" "vpc_2_consumer" {
  ami                    = local.main_ami
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.pri_sn1_az1_2.id
  associate_public_ip_address = false
  key_name = "euc1-kp"
  vpc_security_group_ids = [aws_security_group.ssm_client_2.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = merge(local.common_tags, {
    Name = "${local.instance_name}-2"
  })

  provider = aws.service_consumer_main
}



output "vpc_2_consumer_session_manager_link" {
  value = "https://console.aws.amazon.com/systems-manager/session-manager/${aws_instance.vpc_2_consumer.id}"
}