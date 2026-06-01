resource "aws_instance" "caldera" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.caldera_instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.caldera.id]
  key_name                    = aws_key_pair.operator.key_name
  associate_public_ip_address = false

  user_data = file("${path.module}/files/caldera.sh.tpl")

  root_block_device {
    volume_size = 20
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = { Name = "${var.lab_name}-caldera" }
}
