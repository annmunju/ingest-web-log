AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "ap-northeast-2")
export AWS_ACCOUNT_ID AWS_REGION

terraform init
terraform apply -target=aws_ecr_repository.kafka_producer -auto-approve

docker buildx build \
  --platform linux/arm64 \
  -t kafka-producer:latest \
  --load \
  .

docker tag kafka-producer:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/kafka-producer:latest

aws ecr get-login-password \
  --region $AWS_REGION \
| docker login \
  --username AWS \
  --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/kafka-producer:latest

terraform apply -auto-approve