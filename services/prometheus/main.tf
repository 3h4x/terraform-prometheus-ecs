locals {
  config_bucket_name = "${var.name}.${var.domain}"
  vpc_subnets        = split(",", var.vpc_subnets)

  az_map = {
    "us-west-2a" = 0
    "us-west-2b" = 1
    "us-west-2c" = 2
  }
}

resource "aws_autoscaling_group" "prometheus" {
  name                      = var.name
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  launch_configuration      = aws_launch_configuration.prometheus.name
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  vpc_zone_identifier  = [element(local.vpc_subnets, local.az_map[var.availability_zone])]
  termination_policies = ["OldestInstance"]
  availability_zones   = [var.availability_zone]

  enabled_metrics = [
    "GroupTotalInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMinSize",
    "GroupMaxSize",
  ]

  tag {
    key                 = "Name"
    value               = "${var.name}-instance"
    propagate_at_launch = true
  }

  depends_on = [aws_launch_configuration.prometheus]
}

# EC2 cluster instances - booting script
data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  # Pick latest Amazon Linux AMI v2 optimized for ECS
  name_regex = "amzn2-ami-ecs-hvm-2.0.*-x86_64-ebs"
}

resource "aws_launch_configuration" "prometheus" {
  name_prefix          = "${var.name}-"
  iam_instance_profile = var.instance_profile_name
  image_id             = data.aws_ami.ecs.image_id
  instance_type        = var.instance_size
  security_groups      = [aws_security_group.prometheus.id]
  user_data            = data.template_file.user_data.rendered

  depends_on = [aws_security_group.prometheus]

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 cluster instances - booting script
data "template_file" "user_data" {
  template = file("${path.module}/files/userdata.yml")

  vars = {
    aws_region        = var.region
    bucket_config     = aws_s3_bucket.config.id
    ebs_id_prometheus = aws_ebs_volume.prometheus.id
    ebs_id_grafana    = aws_ebs_volume.grafana.id
    cluster_name      = aws_ecs_cluster.prometheus.name
  }
}

resource "aws_security_group" "prometheus" {
  name        = var.name
  description = "${var.name} Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-${var.name}-alb"
  }
}

output "security_group_id" {
  value = aws_security_group.prometheus.id
}

resource "aws_security_group_rule" "egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.prometheus.id
  to_port           = 0
  type              = "egress"
}

# Allow access from jump host
resource "aws_security_group_rule" "allow_jump_host_ssh" {
  from_port                = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = var.security_group_id_jump_host
  to_port                  = 22
  type                     = "ingress"
}

resource "aws_security_group_rule" "allow_jump_host_http_prometheus" {
  from_port                = 9090
  protocol                 = "tcp"
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = var.security_group_id_jump_host
  to_port                  = 9090
  type                     = "ingress"
}

resource "aws_security_group_rule" "allow_jump_host_http_grafana" {
  from_port                = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = var.security_group_id_jump_host
  to_port                  = 3000
  type                     = "ingress"
}

resource "aws_security_group_rule" "allow_jump_host_http_alertmanager" {
  from_port                = 9093
  protocol                 = "tcp"
  security_group_id        = aws_security_group.prometheus.id
  source_security_group_id = var.security_group_id_jump_host
  to_port                  = 9093
  type                     = "ingress"
}

