resource "aws_instance" "target" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.target_instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.target.id]
  key_name                    = aws_key_pair.operator.key_name
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/files/atomic_redteam.sh.tpl", {
    siem_ip = aws_instance.siem.private_ip
  })

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags       = { Name = "${var.lab_name}-target" }
  depends_on = [aws_instance.siem]
}
