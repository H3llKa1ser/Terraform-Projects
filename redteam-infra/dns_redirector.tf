resource "aws_instance" "dns_redirector" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.dns_redirector_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.dns_redirector.id]
  key_name               = aws_key_pair.operator.key_name

  user_data = templatefile("${path.module}/files/dns_redirector.sh.tpl", {
    team_server_ip    = aws_instance.team_server.private_ip
    dns_listener_port = var.dns_listener_port
  })

  root_block_device {
    volume_size = 10
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags       = { Name = "${var.engagement_name}-dns-redirector" }
  depends_on = [aws_instance.team_server]
}
