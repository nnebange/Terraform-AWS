# --- loadbalancing/main.tf ---

resource "aws_lb" "hiba_lb" {
  name            = "hiba-loadbalancer"
  subnets         = var.public_subnets
  security_groups = [var.public_sg]
  idle_timeout    = 400
}
# ------ target group -------------

resource "aws_lb_target_group" "hiba_tg" {
  name     = "hiba-lb-tg-${substr(uuid(), 0, 3)}"
  port     = var.tg_port
  protocol = var.tg_protocol
  vpc_id   = var.vpc_id

# Lifecycle policy because of uuid() function will change every time we run terraform apply.
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
  health_check {
    healthy_threshold   = var.elb_healthy_threshold
    unhealthy_threshold = var.elb_unhealthy_threshold
    timeout             = var.elb_timeout
    interval            = var.elb_interval
  }
}

resource "aws_lb_listener" "hiba_lb_listener" {
  load_balancer_arn = aws_lb.hiba_lb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hiba_tg.arn
  }
}