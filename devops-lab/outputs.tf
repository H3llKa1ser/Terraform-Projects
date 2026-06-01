output "s3_bucket" {
  value = aws_s3_bucket.uploads.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.events.name
}

output "sqs_queue_url" {
  value = aws_sqs_queue.tasks.id
}

output "lambda_function" {
  value = aws_lambda_function.processor.function_name
}
