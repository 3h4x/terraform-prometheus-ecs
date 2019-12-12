variable "name" {
  default = "prometheus"
}

variable "instance_size" {
  # TODO change after tests
  default = "t3.medium"
}

variable "availability_zone" {
}

variable "cloudmap_internal_id" {
}

variable "domain" {
}

variable "ecs_cluster_id" {
}

variable "ecs_cluster_private_security_group_id" {
}

variable "instance_profile_name" {
}

variable "instance_role_name" {
}

variable "region" {
}

variable "security_group_id_jump_host" {
}

variable "vpc_id" {
}

variable "vpc_subnets" {
}

