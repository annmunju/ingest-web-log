IMAGE_IDS=$(aws ecr list-images \
  --repository-name kafka-producer \
  --query 'imageIds[*]' \
  --output json)

# 이미지 삭제
aws ecr batch-delete-image \
  --repository-name kafka-producer \
  --image-ids "$IMAGE_IDS"

# Terraform destroy 실행
terraform destroy -auto-approve