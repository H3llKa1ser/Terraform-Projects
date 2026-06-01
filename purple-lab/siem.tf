resource "aws_instance" "siem" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.siem_instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.siem.id]
  key_name                    = aws_key_pair.operator.key_name
  associate_public_ip_address = false

  user_data = file("${path.module}/files/wazuh_manager.sh.tpl")

  root_block_device {
    volume_size = 50   # Wazuh indices grow; give it headroom
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = { Name = "${var.lab_name}-siem" }
}
