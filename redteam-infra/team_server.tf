data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "operator" {
  key_name   = "${var.engagement_name}-operator-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "team_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.team_server_instance_type
  subnet_id              = aws_subnet.private.id          # private subnet
  vpc_security_group_ids = [aws_security_group.team_server.id]
  key_name               = aws_key_pair.operator.key_name
  associate_public_ip_address = false                     # NO public IP

  user_data = file("${path.module}/files/harden.sh")

  root_block_device {
    volume_size = 30
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = { Name = "${var.engagement_name}-teamserver" }
}
