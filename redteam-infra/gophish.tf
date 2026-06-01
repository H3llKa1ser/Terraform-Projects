resource "aws_instance" "gophish" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.gophish_instance_type
  subnet_id                   = aws_subnet.private.id     # private subnet
  vpc_security_group_ids      = [aws_security_group.gophish.id]
  key_name                    = aws_key_pair.operator.key_name
  associate_public_ip_address = false                     # NO public IP

  user_data = templatefile("${path.module}/files/gophish_install.sh.tpl", {
    gophish_admin_port = var.gophish_admin_port
    gophish_phish_port = var.gophish_phish_port
  })

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = { Name = "${var.engagement_name}-gophish" }
}
