provider "aws" {
  region = "ap-northeast-2"
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

# Kafka 인스턴스
resource "aws_instance" "kafka" {
  ami                    = var.ami_id # 변수로 전달받은 AMI ID 사용
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[0]
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
