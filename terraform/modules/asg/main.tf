resource "aws_launch_template" "asg_lt" {
  name_prefix   = var.lt_name
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.instance_sg_id]
  }

  user_data = base64encode(var.user_data)

  tag_specifications {
    resource_type = "instance"

    tags = var.tags
  }
}

resource "aws_autoscaling_group" "asg" {
  name                = var.asg_name
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.private_subnet_ids

  target_group_arns = [var.target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.asg_name
    propagate_at_launch = true
  }
}