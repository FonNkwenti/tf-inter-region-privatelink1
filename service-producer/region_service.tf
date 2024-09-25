#####################################################
## PrivateLink Service in main Region
#####################################################

resource "aws_lb" "region_private_nlb" {
  name               = "app-region-private-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = module.service_provider_region.private_subnets
#   subnets            = module.service_provider_region.private_subnets
  security_groups    = [aws_security_group.region_endpoint_service.id]

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
  provider = aws.service_provider_region
}

data "aws_autoscaling_group" "main_private_nlb" {
  name = aws_autoscaling_group.application.name
  provider = aws.service_provider_main
}


resource "aws_lb_target_group" "region_private_nlb_tg" {
  name        = "app-region-private-nlb-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = module.service_provider_region.vpc_id
  target_type = "ip"


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
  provider = aws.service_provider_region
}

resource "aws_lb_listener" "region_private_nlb_listener" {
  load_balancer_arn = aws_lb.region_private_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.region_private_nlb_tg.arn
  }
  tags = local.common_tags

  provider = aws.service_provider_region

}

# resource "aws_lb_target_group_attachment" "region_private_nlb_tg_attachment" {
#   for_each = {
#     for instance in data.aws_autoscaling_group.main_private_nlb.instances :
#     instance.id => instance
#   }

#   target_group_arn = aws_lb_target_group.region_private_nlb_tg.arn
#   target_id        = each.key  # This is the instance ID
#   port             = 80
# }


resource "aws_vpc_endpoint_service" "region" {
  acceptance_required        = false # should be true in real life
  network_load_balancer_arns = [aws_lb.region_private_nlb.arn]
  allowed_principals         = ["arn:aws:iam::${var.cross_account_id}:root"]

  tags = local.common_tags

  provider = aws.service_provider_region

}




resource "aws_security_group" "region_endpoint_service" {
  name        = "region-endpoint-service"
  description = "Allow HTTP/HTTPS traffic from consumers"
  vpc_id      = module.service_provider_region.vpc_id

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
    Name = "region-endpoint-service"
  })
  provider = aws.service_provider_region
}