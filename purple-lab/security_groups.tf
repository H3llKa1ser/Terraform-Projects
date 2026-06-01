# ---------- Bastion: operator SSH only ----------
resource "aws_security_group" "bastion" {
  name        = "${var.lab_name}-bastion-sg"
  description = "Bastion - operator SSH"
  vpc_id      = aws_vpc.lab.id
  tags        = { Name = "${var.lab_name}-bastion-sg" }
}

resource "aws_security_group_rule" "bastion_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.operator_cidrs
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from operators"
}

resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

# ---------- SIEM (Wazuh) ----------
resource "aws_security_group" "siem" {
  name        = "${var.lab_name}-siem-sg"
  description = "Wazuh SIEM"
  vpc_id      = aws_vpc.lab.id
  tags        = { Name = "${var.lab_name}-siem-sg" }
}

# SSH + dashboard (443) from bastion only
resource "aws_security_group_rule" "siem_ssh_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.siem.id
}

resource "aws_security_group_rule" "siem_dashboard_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.siem.id
  description              = "Wazuh dashboard via bastion tunnel"
}

# Wazuh agent enrollment (1515) + events (1514) from lab hosts
resource "aws_security_group_rule" "siem_agent_enroll" {
  type        = "ingress"
  from_port   = 1515
  to_port     = 1515
  protocol    = "tcp"
  cidr_blocks = [aws_subnet.private.cidr_block]
  security_group_id = aws_security_group.siem.id
  description = "Wazuh agent enrollment"
}

resource "aws_security_group_rule" "siem_agent_events" {
  type        = "ingress"
  from_port   = 1514
  to_port     = 1514
  protocol    = "tcp"
  cidr_blocks = [aws_subnet.private.cidr_block]
  security_group_id = aws_security_group.siem.id
  description = "Wazuh agent events"
}

resource "aws_security_group_rule" "siem_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.siem.id
}

# ---------- Target (victim) ----------
resource "aws_security_group" "target" {
  name        = "${var.lab_name}-target-sg"
  description = "Victim host"
  vpc_id      = aws_vpc.lab.id
  tags        = { Name = "${var.lab_name}-target-sg" }
}

resource "aws_security_group_rule" "target_ssh_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.target.id
}

# Allow Caldera to drive the target within the lab subnet
resource "aws_security_group_rule" "target_from_lab" {
  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = [aws_subnet.private.cidr_block]
  security_group_id = aws_security_group.target.id
  description = "Intra-lab traffic (emulation)"
}

resource "aws_security_group_rule" "target_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.target.id
}

# ---------- Caldera (emulation) ----------
resource "aws_security_group" "caldera" {
  name        = "${var.lab_name}-caldera-sg"
  description = "MITRE Caldera C2/emulation"
  vpc_id      = aws_vpc.lab.id
  tags        = { Name = "${var.lab_name}-caldera-sg" }
}

resource "aws_security_group_rule" "caldera_ssh_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.caldera.id
}

# Caldera web UI (8888) via bastion tunnel
resource "aws_security_group_rule" "caldera_ui_bastion" {
  type                     = "ingress"
  from_port                = 8888
  to_port                  = 8888
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.caldera.id
  description              = "Caldera web UI via bastion tunnel"
}

# Agents (on the target) beacon back to Caldera from within the lab subnet
resource "aws_security_group_rule" "caldera_agent_callback" {
  type              = "ingress"
  from_port         = 8888
  to_port           = 8888
  protocol          = "tcp"
  cidr_blocks       = [aws_subnet.private.cidr_block]
  security_group_id = aws_security_group.caldera.id
  description       = "Caldera agent (Sandcat) callbacks from lab hosts"
}

resource "aws_security_group_rule" "caldera_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.caldera.id
}
