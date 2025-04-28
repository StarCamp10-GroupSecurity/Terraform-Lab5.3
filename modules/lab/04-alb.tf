#####################
#        ALB        #
#####################

# Security Group for ALB
resource "aws_security_group" "ALB_SG" {
  name        = "${var.proj}-sg-alb-${var.environment}"
  description = "Allow HTTP, HTTPS inbound and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress = [
    {
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "Allow inbound traffic on port 80"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "Allow inbound traffic on port 443"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.proj}-sg-alb-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_alb" "main" {
  name               = "${var.proj}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ALB_SG.id]
  subnets            = values(aws_subnet.public_subnets)[*].id

  enable_deletion_protection = false


  tags = {
    Environment = var.environment
    Name        = "${var.proj}-alb-${var.environment}"
  }
}

## Target Group for our service
resource "aws_alb_target_group" "alb_target_group_lab_5_3" {
  name                 = "${var.proj}-targetgroup-${var.environment}"
  port                 = "443"
  protocol             = "HTTPS"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 120

  health_check {
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    interval            = "60"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTPS"
    timeout             = "30"
  }
}

resource "aws_alb_listener" "alb_listener_http" {
  load_balancer_arn = aws_alb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "alb_listener_https" {
  load_balancer_arn = aws_alb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb_target_group_lab_5_3.arn
  }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.ec2_autoscaling_group.id
  lb_target_group_arn    = aws_alb_target_group.alb_target_group_lab_5_3.arn
}
