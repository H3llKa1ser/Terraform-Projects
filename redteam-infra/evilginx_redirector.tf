resource "aws_instance" "evilginx_redirector" {
  count                  = var.enable_evilginx_redirector ? 1 : 0
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.evilginx_redirector_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.evilginx_redirector[0].id]
  key_name               = aws_key_pair.operator.key_name

  user_data = templatefile("${path.module}/files/evilginx_redirector.sh.tpl", {
    evilginx_ip = aws_instance.evilginx.private_ip
  })

  root_block_device {
    volume_size = 10
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags       = { Name = "${var.engagement_name}-evilginx-redirector" }
  depends_on = [aws_instance.evilginx]
}
