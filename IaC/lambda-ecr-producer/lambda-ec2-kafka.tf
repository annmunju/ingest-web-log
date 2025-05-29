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

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "kafka_producer" {
  function_name = "kafka-producer"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.kafka_producer.repository_url}:latest"
  role          = aws_iam_role.lambda_exec.arn
  architectures = ["arm64"]

  vpc_config {
    subnet_ids         = var.subnet_ids            # 프라이빗 서브넷 ID 목록
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      BOOTSTRAP_SERVERS = "10.0.1.44:9092"  # ex) 10.0.2.35:9092
      KAFKA_TOPIC       = "clickstream"
    }
  }
}

resource "aws_security_group_rule" "allow_lambda_to_kafka" {
  type                     = "ingress"
  from_port                = 9092
  to_port                  = 9092
  protocol                 = "tcp"
  security_group_id        = aws_security_group.kafka_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id    # 아래에 만들 Lambda SG
}


# Kafka 보안을 위한 보안 그룹
resource "aws_security_group" "kafka_sg" {
  name        = "kafka-sg"
  description = "Allow SSH, ZK(2181), Kafka(9092)"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["221.146.77.37/32"]
  }
  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = ["221.146.77.37/32"]
  }
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda-kafka-sg"
  description = "Allow outbound to Kafka broker"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]        # VPC CIDR 혹은 kafka EC2 사설 IP 범위
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Kafka 인스턴스
resource "aws_instance" "kafka" {
  ami                    = var.ami_id # 변수로 전달받은 AMI ID 사용
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[0]
  private_ip             = "10.0.1.44"
  vpc_security_group_ids = [aws_security_group.kafka_sg.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = var.ebs_volume_size
    volume_type = "gp2"
  }

  tags = {
    Name = "kh-poc"
  }
}
