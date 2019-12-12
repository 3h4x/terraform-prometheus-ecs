# TODO move to separate repository, it shouldn't be defined in tf

# Config bucket should be shared for all prometheus instances
resource "aws_s3_bucket" "config" {
  bucket = local.config_bucket_name
  acl    = "private"

  tags = {
    Name = local.config_bucket_name
  }
}

# Prometheus config
data "template_file" "prometheus_config" {
  template = file("${path.module}/files/prometheus/config.yml")
}

resource "aws_s3_bucket_object" "prometheus_config" {
  bucket  = aws_s3_bucket.config.id
  key     = "prometheus/prometheus.yml"
  content = data.template_file.prometheus_config.rendered

  etag = md5(data.template_file.prometheus_config.rendered)
}

data "template_file" "prometheus_alerts_global" {
  template = file("${path.module}/files/prometheus/alerts/global.yml")
}

resource "aws_s3_bucket_object" "prometheus_alerts_global" {
  bucket  = aws_s3_bucket.config.id
  key     = "prometheus/alerts/global.yml"
  content = data.template_file.prometheus_alerts_global.rendered

  etag = md5(data.template_file.prometheus_alerts_global.rendered)
}

# Alertmanager config
data "template_file" "alertmanager_config" {
  template = file("${path.module}/files/alertmanager/config.yml")
}

resource "aws_s3_bucket_object" "alertmanager_config" {
  bucket  = aws_s3_bucket.config.id
  key     = "alertmanager/alertmanager.yml"
  content = data.template_file.alertmanager_config.rendered

  etag = md5(data.template_file.alertmanager_config.rendered)
}

data "template_file" "alertmanager_template_slack" {
  template = file("${path.module}/files/alertmanager/templates/slack.tmpl")
}

resource "aws_s3_bucket_object" "alertmanager_template_slack" {
  bucket  = aws_s3_bucket.config.id
  key     = "alertmanager/templates/slack.tmpl"
  content = data.template_file.alertmanager_template_slack.rendered

  etag = md5(data.template_file.alertmanager_template_slack.rendered)
}

