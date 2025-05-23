# VPC에 퍼블릭 서브넷, 인터넷 게이트웨이, 라우팅 테이블, 카프카 EC2 인스턴스 생성

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "kafka_igw" {
  vpc_id = var.vpc_id
  tags = {
    Name = "kafka-igw"
  }
}

# 퍼블릭 서브넷 생성 (서울 리전 ap-northeast-2a 사용)
resource "aws_subnet" "kafka_public_subnet" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "kafka-public-subnet"
  }
}

# 라우팅 테이블 생성 및 IGW 연결
resource "aws_route_table" "kafka_public_rt" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kafka_igw.id
  }

  tags = {
    Name = "kafka-public-rt"
  }
}

# 퍼블릭 서브넷에 라우팅 테이블 연결
resource "aws_route_table_association" "kafka_public_rta" {
  subnet_id      = aws_subnet.kafka_public_subnet.id
  route_table_id = aws_route_table.kafka_public_rt.id
}

# 카프카용 보안 그룹 (SSH 및 카프카 포트 허용 예시)
resource "aws_security_group" "kafka_setup_sg" {
  name        = "kafka-setup-sg"
  description = "Allow SSH and Kafka ports"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  tags = {
    Name = "kafka-sg"
  }
}

# 최신 Amazon Linux 2 AMI 데이터 소스
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 카프카 EC2 인스턴스 생성
resource "aws_instance" "kafka_setup" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.kafka_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.kafka_setup_sg.id]
  associate_public_ip_address = true

  key_name = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    # 1) 시스템 업데이트
    yum update -y

    # 2) Java 설치 (OpenJDK 11)
    amazon-linux-extras install java-openjdk11 -y

    # 3) Confluent Platform 7.4.1 다운로드 및 설치
    wget https://packages.confluent.io/archive/7.4/confluent-community-7.4.1.tar.gz -P /opt
    tar xzf /opt/confluent-community-7.4.1.tar.gz -C /opt
    ln -s /opt/confluent-7.4.1 /opt/confluent

    # 4) Kafka 브로커 설정
    sed -i 's|^#listeners=.*|listeners=PLAINTEXT://0.0.0.0:9092|' /opt/confluent/etc/kafka/server.properties
    sed -i 's|^#advertised.listeners=.*|advertised.listeners=PLAINTEXT://'"$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"':9092|' /opt/confluent/etc/kafka/server.properties

    # 5) systemd 서비스 파일 생성
    cat << 'EOT' > /etc/systemd/system/zookeeper.service
    [Unit]
    Description=Apache Zookeeper
    After=network.target

    [Service]
    Type=simple
    ExecStart=/opt/confluent/bin/zookeeper-server-start /opt/confluent/etc/kafka/zookeeper.properties
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    EOT

    cat << 'EOT' > /etc/systemd/system/kafka.service
    [Unit]
    Description=Apache Kafka
    After=zookeeper.service

    [Service]
    Type=simple
    ExecStart=/opt/confluent/bin/kafka-server-start /opt/confluent/etc/kafka/server.properties
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    EOT

    # 6) 서비스 등록 및 시작
    sudo systemctl daemon-reload
    sudo systemctl enable zookeeper.service kafka.service
    sudo systemctl start zookeeper.service kafka.service
    EOF

  tags = {
    Name = "kafka-setup"
  }
}

output "kafka_public_ip" {
  value       = aws_instance.kafka_setup.public_ip
  description = "카프카 서버의 퍼블릭 IP"
}
