resource "aws_elb" "metrics" {
  name                      = "${var.env}-metrics"
  subnets                   = ["${split(",", var.infra_subnet_ids)}"]
  idle_timeout              = "${var.elb_idle_timeout}"
  cross_zone_load_balancing = "true"

  security_groups = [
    "${aws_security_group.metrics_elb.id}",
  ]

  health_check {
    target              = "TCP:3000"
    interval            = "${var.health_check_interval}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy}"
    unhealthy_threshold = "${var.health_check_unhealthy}"
  }

  listener {
    instance_port      = 3000
    instance_protocol  = "tcp"
    lb_port            = 443
    lb_protocol        = "ssl"
    ssl_certificate_id = "${var.system_domain_cert_arn}"
  }

  listener {
    instance_port      = 3001
    instance_protocol  = "tcp"
    lb_port            = 3001
    lb_protocol        = "ssl"
    ssl_certificate_id = "${var.system_domain_cert_arn}"
  }
}

resource "aws_load_balancer_listener_policy" "metrics_listener_policies_443" {
  load_balancer_name = "${aws_elb.metrics.name}"
  load_balancer_port = 443

  policy_names = [
    "${var.default_elb_security_policy}",
  ]
}

resource "aws_load_balancer_listener_policy" "metrics_listener_policies_3001" {
  load_balancer_name = "${aws_elb.metrics.name}"
  load_balancer_port = 3001

  policy_names = [
    "${var.default_elb_security_policy}",
  ]
}
