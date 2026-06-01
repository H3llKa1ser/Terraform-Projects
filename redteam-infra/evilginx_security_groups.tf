# ============================================================
#  EVILGINX SG
#  Public edge for DNS(53) + ACME/HTTP(80) + HTTPS(443).
#  When the L4 redirector is enabled, 80/443 are locked to the
#  redirector SG; 53 stays public (Evilginx must answer DNS for
#  NS delegation + Let's Encrypt). SSH is bastion-only.
# ============================================================
resource "aws_security_group" "evilginx" {
  name        = "${var.engagement_name}-evilginx-sg"
  description = "Evilginx AiTM proxy"
  vpc_id      = aws_vpc.rt.id
  tags        = { Name = "${var.engagement_name}-evilginx-sg" }
}

# --- SSH: bastion only ---
resource "aws_security_group_rule" "eg_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.evilginx.id
  description              = "SSH from bastion only"
}

# --- 80/443 from the L4 redirector only (when enabled) ---
resource "aws_security_group_rule" "eg_https_from_redirector" {
  count                    = var.enable_evilginx_redirector ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.evilginx_redirector[0].id
  security_group_id        = aws_security_group.evilginx.id
  description              = "HTTPS from L4 redirector only"
}

resource "aws_security_group_rule" "eg_http_from_redirector" {
  count                    = var.enable_evilginx_redirector ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.evilginx_redirector[0].id
  security_group_id        = aws_security_group.evilginx.id
  description              = "HTTP(ACME) from L4 redirector only"
}

# --- 80/443 public (when NO redirector) ---
resource "aws_security_group_rule" "eg_https_public" {
  count             = var.enable_evilginx_redirector ? 0 : 1
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.evilginx.id
  description       = "HTTPS direct"
}

resource "aws_security_group_rule" "eg_http_public" {
  count             = var.enable_evilginx_redirector ? 0 : 1
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.evilginx.id
  description       = "HTTP(ACME) direct"
}

# --- DNS 53 (UDP+TCP) must be public for NS delegation + ACME ---
resource "aws_security_group_rule" "eg_dns_udp_public" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.evilginx.id
  description       = "Evilginx authoritative DNS (UDP)"
}

resource "aws_security_group_rule" "eg_dns_tcp_public" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.evilginx.id
  description       = "Evilginx authoritative DNS (TCP)"
}

resource "aws_security_group_rule" "eg_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.evilginx.id
}

# ============================================================
#  EVILGINX L4 REDIRECTOR SG  (TCP passthrough, no TLS decrypt)
# ============================================================
resource "aws_security_group" "evilginx_redirector" {
  count       = var.enable_evilginx_redirector ? 1 : 0
  name        = "${var.engagement_name}-egredir-sg"
  description = "Evilginx L4 TCP passthrough redirector"
  vpc_id      = aws_vpc.rt.id
  tags        = { Name = "${var.engagement_name}-egredir-sg" }
}

resource "aws_security_group_rule" "egr_ssh_from_bastion" {
  count                    = var.enable_evilginx_redirector ? 1 : 0
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.evilginx_redirector[0].id
  description              = "SSH from bastion only"
}

resource "aws_security_group_rule" "egr_https_public" {
  count             = var.enable_evilginx_redirector ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.evilginx_redirector[0].id
  description       = "HTTPS passthrough in"
}

resource "aws_security_group_rule" "egr_http_public" {
  count             = var.enable_evilginx_redirector ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.evilginx_redirector[0].id
  description       = "HTTP passthrough in"
}

resource "aws_security_group_rule" "egr_egress" {
  count             = var.enable_evilginx_redirector ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.evilginx_redirector[0].id
}
