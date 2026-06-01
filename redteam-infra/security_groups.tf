# ============================================================
#  BASTION SG  — sole SSH entry point, operator IPs only
# ============================================================
resource "aws_security_group" "bastion" {
  name        = "${var.engagement_name}-bastion-sg"
  description = "Bastion host - operator SSH only"
  vpc_id      = aws_vpc.rt.id
  tags        = { Name = "${var.engagement_name}-bastion-sg" }
}

resource "aws_security_group_rule" "bastion_ssh_operators" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.operator_cidrs
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from operators only"
}

resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

# ============================================================
#  TEAM SERVER SG  — fully private. No public ingress at all.
# ============================================================
resource "aws_security_group" "team_server" {
  name        = "${var.engagement_name}-teamserver-sg"
  description = "C2 team server - private only"
  vpc_id      = aws_vpc.rt.id
  tags        = { Name = "${var.engagement_name}-teamserver-sg" }
}

# SSH ONLY from the bastion
resource "aws_security_group_rule" "ts_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.team_server.id
  description              = "SSH from bastion only"
}

# C2 management console ONLY from the bastion (operators tunnel through it)
resource "aws_security_group_rule" "ts_mgmt_from_bastion" {
  type                     = "ingress"
  from_port                = 31337
  to_port                  = 31337
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.team_server.id
  description              = "C2 console from bastion (via SSH tunnel)"
}

# HTTPS C2 listener traffic ONLY from the HTTP redirector
resource "aws_security_group_rule" "ts_https_from_redirector" {
  type                     = "ingress"
  from_port                = var.c2_listener_port
  to_port                  = var.c2_listener_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.redirector.id
  security_group_id        = aws_security_group.team_server.id
  description              = "HTTPS C2 from HTTP redirector only"
}

# DNS C2 listener traffic ONLY from the DNS redirector (UDP + TCP/53)
resource "aws_security_group_rule" "ts_dns_udp_from_redirector" {
  type                     = "ingress"
  from_port                = var.dns_listener_port
  to_port                  = var.dns_listener_port
  protocol                 = "udp"
  source_security_group_id = aws_security_group.dns_redirector.id
  security_group_id        = aws_security_group.team_server.id
  description              = "DNS C2 (UDP) from DNS redirector only"
}

resource "aws_security_group_rule" "ts_dns_tcp_from_redirector" {
  type                     = "ingress"
  from_port                = var.dns_listener_port
  to_port                  = var.dns_listener_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.dns_redirector.id
  security_group_id        = aws_security_group.team_server.id
  description              = "DNS C2 (TCP) from DNS redirector only"
}

resource "aws_security_group_rule" "ts_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.team_server.id
}

# ============================================================
#  HTTP REDIRECTOR SG  — public HTTPS in, SSH from bastion
# ============================================================
resource "aws_security_group" "redirector" {
  name        = "${var.engagement_name}-redirector-sg"
  description = "Public HTTP(S) redirector"
  vpc_id      = aws_vpc.rt.id
  tags        = { Name = "${var.engagement_name}-redirector-sg" }
}

resource "aws_security_group_rule" "rd_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.redirector.id
  description              = "SSH from bastion only"
}

resource "aws_security_group_rule" "rd_https_public" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redirector.id
  description       = "HTTPS beacon traffic"
}

resource "aws_security_group_rule" "rd_http_public" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redirector.id
  description       = "HTTP for ACME / redirect"
}

resource "aws_security_group_rule" "rd_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redirector.id
}

# ============================================================
#  DNS REDIRECTOR SG  — public UDP/TCP 53 in, SSH from bastion
# ============================================================
resource "aws_security_group" "dns_redirector" {
  name        = "${var.engagement_name}-dnsredir-sg"
  description = "Public DNS redirector"
  vpc_id      = aws_vpc.rt.id
  tags        = { Name = "${var.engagement_name}-dnsredir-sg" }
}

resource "aws_security_group_rule" "dnsrd_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.dns_redirector.id
  description              = "SSH from bastion only"
}

resource "aws_security_group_rule" "dnsrd_udp_public" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dns_redirector.id
  description       = "DNS beacon traffic (UDP)"
}

resource "aws_security_group_rule" "dnsrd_tcp_public" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dns_redirector.id
  description       = "DNS beacon traffic (TCP fallback)"
}

resource "aws_security_group_rule" "dnsrd_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dns_redirector.id
}

# ============================================================
#  GOPHISH SG  — fully private. Admin via bastion, phishing via redirector.
# ============================================================
resource "aws_security_group" "gophish" {
  name        = "${var.engagement_name}-gophish-sg"
  description = "GoPhish phishing server - private only"
  vpc_id      = aws_vpc.rt.id
  tags        = { Name = "${var.engagement_name}-gophish-sg" }
}

# SSH ONLY from the bastion
resource "aws_security_group_rule" "gp_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.gophish.id
  description              = "SSH from bastion only"
}

# Admin UI ONLY from the bastion (operators tunnel through it)
resource "aws_security_group_rule" "gp_admin_from_bastion" {
  type                     = "ingress"
  from_port                = var.gophish_admin_port
  to_port                  = var.gophish_admin_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.gophish.id
  description              = "GoPhish admin UI from bastion (via SSH tunnel)"
}

# Phishing landing pages ONLY from the phishing redirector
resource "aws_security_group_rule" "gp_phish_from_redirector" {
  type                     = "ingress"
  from_port                = var.gophish_phish_port
  to_port                  = var.gophish_phish_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.phish_redirector.id
  security_group_id        = aws_security_group.gophish.id
  description              = "Landing page traffic from phishing redirector only"
}

resource "aws_security_group_rule" "gp_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gophish.id
  description       = "Outbound for SMTP relay, updates"
}

# ============================================================
#  PHISHING REDIRECTOR SG  — public HTTPS in, SSH from bastion
# ============================================================
resource "aws_security_group" "phish_redirector" {
  name        = "${var.engagement_name}-phishredir-sg"
  description = "Public phishing landing redirector"
  vpc_id      = aws_vpc.rt.id
  tags        = { Name = "${var.engagement_name}-phishredir-sg" }
}

resource "aws_security_group_rule" "pr_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.phish_redirector.id
  description              = "SSH from bastion only"
}

resource "aws_security_group_rule" "pr_https_public" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.phish_redirector.id
  description       = "HTTPS landing page traffic"
}

resource "aws_security_group_rule" "pr_http_public" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.phish_redirector.id
  description       = "HTTP for ACME / redirect"
}

resource "aws_security_group_rule" "pr_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.phish_redirector.id
}
