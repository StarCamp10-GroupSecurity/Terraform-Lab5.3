#####################
#        ASG        #
#####################

resource "aws_security_group" "LaunchTemplate_EC2_SG" {
  name        = "${var.proj}-sg-asg-ec2-${var.environment}"
  description = "Allow traffic from ALB_SG and 22 from Bastion"
  vpc_id      = aws_vpc.main.id

  ingress = [
    {
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = []
      description      = "Allow all traffic coming from port 80 from ALB"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.ALB_SG.id]
      self             = false
    },

    {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = []
      description      = "Allow all traffic coming from port 443 from ALB"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = [aws_security_group.ALB_SG.id]
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.proj}-sg-asg-ec2-${var.environment}"
  }
}

# EC2 Launch Template
resource "aws_launch_template" "ec2_launch_template" {
  name                   = "${var.proj}-ec2-template-${var.environment}"
  image_id               = var.my_ami_id
  instance_type          = var.ec2_instance_type
  user_data              = base64encode(file("${path.module}/template.sh"))
  vpc_security_group_ids = [aws_security_group.LaunchTemplate_EC2_SG.id]


  monitoring {
    enabled = true
  }
}

# EC2 Auto Scaling Group
resource "aws_autoscaling_group" "ec2_autoscaling_group" {
  name                  = "${var.proj}-asg-ec2-${var.environment}"
  max_size              = 2
  min_size              = 1
  desired_capacity      = 2
  vpc_zone_identifier   = values(aws_subnet.private_subnets)[*].id
  health_check_type     = "EC2"
  protect_from_scale_in = false

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  launch_template {
    id      = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "Name"
    value               = "${var.proj}-asg-ec2-${var.environment}"
    propagate_at_launch = true
  }

  target_group_arns = [aws_alb_target_group.alb_target_group_lab_5_3.arn]
}
