resource "aws_instance" "redirector" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.redirector_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.redirector.id]
  key_name               = aws_key_pair.operator.key_name

  user_data = templatefile("${path.module}/files/redirector_nginx.conf.tpl", {
    team_server_ip   = aws_instance.team_server.private_ip
    c2_listener_port = var.c2_listener_port
    server_name      = var.redirector_domain != "" ? var.redirector_domain : "_"
  })

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags       = { Name = "${var.engagement_name}-redirector" }
  depends_on = [aws_instance.team_server]
}
