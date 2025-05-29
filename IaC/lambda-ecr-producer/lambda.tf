resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ecr_readonly" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "kafka_producer" {
  function_name = "kafka-producer"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.kafka_producer.repository_url}:latest"
  role          = aws_iam_role.lambda_exec.arn
  architectures = ["arm64"]

  environment {
    variables = {
      BOOTSTRAP_SERVERS = ":9092"  # ex) <ServerIP>:9092
      KAFKA_TOPIC       = "clickstream"
    }
  }
}

