
#####################################################
## EC2 roles for Session Manager
#####################################################

resource "aws_iam_role" "ec2_exec_role" {
  name = "ec2-exec-role"

  assume_role_policy = jsonencode(
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
})

  tags = merge(local.common_tags, {
    tag-key = "ec2-exec-role"
  })

  provider = aws.service_consumer_main
}


resource "aws_iam_policy_attachment" "ssm_manager_attachment" {
  name       = "ec2-exec-attachement"
  roles      = [aws_iam_role.ec2_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_exec_role.name

  provider = aws.service_consumer_main
}





resource "aws_instance" "privateLink_consumer" {
  ami                    = local.main_ami
  instance_type          = "t2.micro"
  subnet_id              = element(module.service_consumer_main.private_subnets, 0)
  associate_public_ip_address = false
  # key_name = "default-euc1"
  vpc_security_group_ids = [aws_security_group.ssm_client.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = merge(local.common_tags, {
    Name = "main-test-instance"
    # Name = local.instance_name
  })

  provider = aws.service_consumer_main
}


// transit ec2 instance
resource "aws_instance" "transit_consumer" {
  ami                    = local.transit_ami
  instance_type          = "t2.micro"
  subnet_id              = element(module.service_consumer_transit.private_subnets, 0)
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.transit_icmp.id]
  # iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = merge(local.common_tags, {
    Name = local.instance_name
  })

  provider = aws.service_consumer_transit
}


resource "aws_security_group" "transit_icmp" {
  name        = "transit-test-instance"
  description = "Allow ICMP pings for tests"
  vpc_id      = module.service_consumer_transit.vpc_id

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
    Name = "transit-test-instance"
  })
  provider = aws.service_consumer_transit
}