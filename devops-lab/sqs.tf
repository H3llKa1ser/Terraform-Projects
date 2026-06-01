resource "aws_sqs_queue" "tasks" {
  name                      = "${var.project_name}-tasks"
  message_retention_seconds = 86400
}
