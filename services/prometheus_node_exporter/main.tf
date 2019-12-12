variable "ecs_cluster_name" {
}

variable "ecs_security_group" {
}

variable "port" {
  default = 9100
}

resource "aws_ecs_service" "node_exporter" {
  name = "node_exporter"

  task_definition = aws_ecs_task_definition.node_exporter.arn
  cluster         = var.ecs_cluster_name

  # One task per node
  scheduling_strategy = "DAEMON"

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_task_definition" "node_exporter" {
  container_definitions = data.template_file.node_exporter.rendered
  family                = "node_exporter"
  network_mode          = "host"

  volume {
    name      = "root"
    host_path = "/"
  }

  volume {
    name      = "var_run"
    host_path = "/var/run"
  }

  volume {
    name      = "sys"
    host_path = "/sys"
  }
}

data "template_file" "node_exporter" {
  # Fail if version is not provided
  template = file("${path.module}/task.json")

  vars = {
    port = var.port
  }
}

# Allow traffic to prometheus node_exporter
# TODO change to prometheus security group when it's deployed
resource "aws_security_group_rule" "ecs_cluster_tcp_events_allow_node_exporter_from_vpc" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  security_group_id = var.ecs_security_group
  cidr_blocks       = ["10.1.0.0/16"]
}

