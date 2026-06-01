resource "aws_instance" "phish_redirector" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.redirector_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.phish_redirector.id]
  key_name               = aws_key_pair.operator.key_name

  user_data = templatefile("${path.module}/files/phish_redirector_nginx.conf.tpl", {
    gophish_ip         = aws_instance.gophish.private_ip
    gophish_phish_port = var.gophish_phish_port
    server_name        = var.phishing_domain != "" ? var.phishing_domain : "_"
  })

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags       = { Name = "${var.engagement_name}-phish-redirector" }
  depends_on = [aws_instance.gophish]
}
