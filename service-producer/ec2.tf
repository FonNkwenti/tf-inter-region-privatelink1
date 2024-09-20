
#####################################################
## EC2 roles for Session Manager
#####################################################

resource "aws_iam_role" "ec2_exec_role" {
  name = "ec2-exec-role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
  })

  tags = merge(local.common_tags, {
    tag-key = "ec2-exec-role"
  })
}


resource "aws_iam_policy_attachment" "ssm_manager_attachment" {
  name       = "ec2-exec-attachement"
  roles      = [aws_iam_role.ec2_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_exec_role.name
}


#######################################################
##  EC2 PrivateLink Service Consumer
#######################################################


resource "aws_instance" "main_test" {
  ami           = local.main_ami
  instance_type = "t2.micro"
  subnet_id     = element(module.service_provider_main.private_subnets, 0)
  #   subnet_id              = aws_subnet.pri_sn1_az1.id
  associate_public_ip_address = false
  #   key_name                    = "default-euw1"
  vpc_security_group_ids = [aws_security_group.main_icmp.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  tags = merge(local.common_tags, {
    Name = "main-test"
  })

  provider = aws.service_provider_main
}


resource "aws_security_group" "main_icmp" {
  name        = "main-test-instance"
  description = "Allow ICMP pings for tests"
  vpc_id      = module.service_provider_main.vpc_id

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "main-test-instance"
  })
  provider = aws.service_provider_main
}

/////////////////
resource "aws_instance" "main_2_test" {
  ami           = local.main_ami
  instance_type = "t2.micro"
  subnet_id     = element(module.service_provider_main_2.private_subnets, 0)
  #   subnet_id              = aws_subnet.pri_sn1_az1.id
  associate_public_ip_address = false
  #   key_name                    = "default-euw1"
  vpc_security_group_ids = [aws_security_group.main_2_icmp.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  tags = merge(local.common_tags, {
    Name = "main-2"
  })

  provider = aws.service_provider_main
}


resource "aws_security_group" "main_2_icmp" {
  name        = "main-2-test-instance"
  description = "Allow ICMP pings for tests"
  vpc_id      = module.service_provider_main_2.vpc_id

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "main-2-test-instance"
  })
  provider = aws.service_provider_main
}




resource "aws_instance" "region_test" {
  ami           = local.region_ami
  instance_type = "t2.micro"
  subnet_id     = element(module.service_provider_region.private_subnets, 0)
  #   subnet_id              = aws_subnet.pri_sn1_az1.id
  associate_public_ip_address = false
  #   key_name                    = "default-euw1"
  vpc_security_group_ids = [aws_security_group.region_icmp.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  tags = merge(local.common_tags, {
    Name = "region-test"
  })

  provider = aws.service_provider_region
}


resource "aws_security_group" "region_icmp" {
  name        = "region-test-instance"
  description = "Allow ICMP pings for tests"
  vpc_id      = module.service_provider_region.vpc_id

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "region-test-instance"
  })
  provider = aws.service_provider_region
}
