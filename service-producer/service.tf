#####################################################
## PrivateLink Service in main Region
#####################################################

resource "aws_lb" "main_private_nlb" {
  name               = "app-main-private-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = module.service_provider_main.private_subnets
  security_groups    = [aws_security_group.main_endpoint_service.id]

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
  provider = aws.service_provider_main
}

resource "aws_lb_target_group" "main_private_nlb_tg" {
  name        = "app-main-private-nlb-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = module.service_provider_main.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    port                = 80
    protocol            = "HTTP"
  }
  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
  provider = aws.service_provider_main
}

resource "aws_lb_listener" "main_private_nlb_listener" {
  load_balancer_arn = aws_lb.main_private_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main_private_nlb_tg.arn
  }
  tags = local.common_tags

  provider = aws.service_provider_main

}


resource "aws_vpc_endpoint_service" "main" {
  acceptance_required        = false # should be true in real life
  network_load_balancer_arns = [aws_lb.main_private_nlb.arn]
  allowed_principals         = ["arn:aws:iam::${var.cross_account_id}:root"]

  tags = local.common_tags

  provider = aws.service_provider_main

}

resource "aws_launch_template" "application" {
  name_prefix   = "application-product"
  image_id      = local.main_ami
  instance_type = "t2.micro"
  user_data     = filebase64("${path.module}/webserver.sh")
  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = element(module.service_provider_main.private_subnets, 0)
    security_groups             = [aws_security_group.application_http.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = local.instance_name
    })
  }

  lifecycle {
    create_before_destroy = true
  }

  provider = aws.service_provider_main

}
resource "aws_autoscaling_group" "application" {
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2
  vpc_zone_identifier = module.service_provider_main.private_subnets
  launch_template {
    id      = aws_launch_template.application.id
    version = "$Latest"
  }
  provider = aws.service_provider_main
}

resource "aws_autoscaling_attachment" "main_private_nlb" {
  autoscaling_group_name = aws_autoscaling_group.application.id
  lb_target_group_arn    = aws_lb_target_group.main_private_nlb_tg.arn
}


resource "aws_security_group" "main_endpoint_service" {
  name        = "main-endpoint-service"
  description = "Allow HTTP/HTTPS traffic from consumers"
  vpc_id      = module.service_provider_main.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "endpoint-service"
  })
  provider = aws.service_provider_main
}

resource "aws_security_group" "application_http" {
  name        = "application-http"
  description = "Allow HTTP/HTTPS traffic from consumers"
  vpc_id      = module.service_provider_main.vpc_id

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # security_groups = [aws_security_group.endpoint_service.id]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "application-http"
  })
  provider = aws.service_provider_main
}







