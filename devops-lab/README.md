# 1. Start LocalStack
docker compose up -d

# 2. Initialize & apply Terraform
terraform init
terraform plan
terraform apply -auto-approve

# 3. Test the stack with the AWS CLI (pointed at LocalStack)
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
ENDPOINT="--endpoint-url=http://localhost:4566"

# List your buckets
aws $ENDPOINT s3 ls

# Send a message to SQS (this triggers the Lambda)
QUEUE_URL=$(terraform output -raw sqs_queue_url)
aws $ENDPOINT sqs send-message --queue-url "$QUEUE_URL" --message-body '{"hello":"world"}'

# Check Lambda logs
aws $ENDPOINT logs describe-log-groups

# 4. Tear it all down
terraform destroy -auto-approve
docker compose down -v
