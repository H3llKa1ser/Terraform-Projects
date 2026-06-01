resource "aws_instance" "evilginx" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.evilginx_instance_type
  subnet_id              = aws_subnet.public.id          # public edge (owns DNS/TLS)
  vpc_security_group_ids = [aws_security_group.evilginx.id]
  key_name               = aws_key_pair.operator.key_name

  user_data = templatefile("${path.module}/files/evilginx_install.sh.tpl", {
    evilginx_domain = var.evilginx_domain
  })

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required" # IMDSv2
  }

  tags = { Name = "${var.engagement_name}-evilginx" }
}
