provider "aws" {
  region = var.region
}

resource "aws_ecr_repository" "kafka_producer" {
  name = "kafka-producer"
#   force_delete  = true
  image_scanning_configuration {
    scan_on_push = true
  }
}

# 수명주기 정책 추가 (3개 이상 이미지 쌓이면 제거됨)
resource "aws_ecr_lifecycle_policy" "kafka_producer_policy" {
  repository = aws_ecr_repository.kafka_producer.name

  policy = <<POLICY
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep only the most recent 3 images",
        "selection": {
          "tagStatus": "any",
          "countType": "imageCountMoreThan",
          "countNumber": 3
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  POLICY
}
