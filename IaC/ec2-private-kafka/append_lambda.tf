resource "aws_security_group_rule" "allow_lambda_to_kafka" {
  type                     = "ingress"
  from_port                = 9092
  to_port                  = 9092
  protocol                 = "tcp"
  security_group_id        = aws_security_group.kafka_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id    # 아래에 만들 Lambda SG
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