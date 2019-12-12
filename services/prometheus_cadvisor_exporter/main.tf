variable "ecs_cluster_name" {
}

variable "ecs_security_group" {
}

variable "port" {
  default = 8080
}

resource "aws_ecs_service" "cadvisor_exporter" {
  name = "cadvisor_exporter"

  task_definition = aws_ecs_task_definition.cadvisor_exporter.arn
  cluster         = var.ecs_cluster_name

  # One task per node
  scheduling_strategy = "DAEMON"

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_task_definition" "cadvisor_exporter" {
  container_definitions = data.template_file.cadvisor_exporter.rendered
  family                = "cadvisor_exporter"
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
    name      = "var_lib_docker"
    host_path = "/var/lib/docker/"
  }

  volume {
    name      = "cgroup"
    host_path = "/cgroup"
  }

  volume {
    name      = "sys"
    host_path = "/sys"
  }
}

data "template_file" "cadvisor_exporter" {
  # Fail if version is not provided
  template = file("${path.module}/task.json")

  vars = {
    port = var.port
  }
}

# Allow traffic to prometheus cadvisor_exporter
# TODO change to prometheus security group when it's deployed
resource "aws_security_group_rule" "ecs_cluster_tcp_events_allow_cadvisor_exporter_from_vpc" {
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  security_group_id = var.ecs_security_group
  cidr_blocks       = ["10.1.0.0/16"]
}

