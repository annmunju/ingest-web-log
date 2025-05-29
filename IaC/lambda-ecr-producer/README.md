# Lambda Container 및 ECR 업로드 가이드

이 문서는 Terraform으로 ECR 리포지토리와 Lambda 함수를 생성하고, Docker 이미지(이 예제에선 `kafka-producer`)를 빌드·푸시하는 방법을 설명합니다.

## 요구 사항

* AWS 계정
* AWS CLI 설치 및 구성 (`aws configure`)
* Terraform 설치 (>= 1.0)
* Docker 설치
* 환경 변수
  ```bash
  export AWS_ACCOUNT_ID=<your_account_id>
  export AWS_REGION=ap-northeast-2   # 혹은 원하는 리전
  ```

## 프로젝트 파일 구조

```
.
├── variables.tf          # VPC, region, subnet_ids 등 공통 변수 정의
├── main.tf               # ECR + Lambda 리소스 정의
├── terraform.tfvars      # 실제 값을 채워 넣은 변수 파일
├── Dockerfile            # kafka-producer 이미지 빌드용 Dockerfile
├── ingest_kafka.py       # Lambda 핸들러 코드
└── requirements.txt      # Python 패키지 목록 (confluent-kafka 등)
```

## 진행 가이드

### 1. Terraform 인프라 프로비저닝

1.  변수 파일 작성
terraform.tfvars 에 아래 값을 채워 넣으세요.

```terraform
region     = "ap-northeast-2"
```

2.  Init & Apply
```bash
cd <프로젝트_루트>
terraform init
terraform apply -auto-approve
```
이 단계에서
- aws_ecr_repository.kafka_producer 리포지토리가 생성되고
- aws_lambda_function.kafka_producer 람다가 :latest 태그를 가리키도록 IAM Role 포함 프로비저닝됩니다.

### 2. Docker 이미지 빌드 & ECR 푸시

Terraform이 ECR 리포지토리를 만들어 준 뒤, 로컬에서 이미지를 빌드하여 푸시해야 Lambda가 실제 컨테이너를 가져다 쓸 수 있습니다.

1.  ECR 로그인
```bash
aws ecr get-login-password \
    --region $AWS_REGION \
| docker login \
    --username AWS \
    --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

2.  Docker 이미지 빌드
```bash
docker build -t kafka-producer -f Dockerfile.kafka .
```

3.  이미지 태그
```bash
docker tag kafka-producer:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/kafka-producer:latest
```

4.  이미지 푸시
```bash
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/kafka-producer:latest
```

- 자동 삭제 정책
    - ECR에 푸시할 때마다 최대 3개의 이미지만 남기고 오래된 이미지는 자동으로 만료(expire)됩니다. (Terraform aws_ecr_lifecycle_policy로 설정되어 있습니다.)

### 3. Lambda 함수 테스트

1.  AWS 콘솔 또는 AWS CLI로 람다 함수를 호출해 보세요.
```bash
aws lambda invoke \
    --function-name kafka-producer \
    --payload '{"key": "value"}' \
    response.json
```

2.  response.json 에서 리턴 값을 확인합니다.

## 결론
- Terraform으로 ECR과 Lambda 인프라를 선언적으로 관리
- Docker로 컨테이너 이미지 빌드 및 ECR 푸시
- 이후 코드 변경 시에는 다시 이미지 빌드+푸시 → Lambda가 최신 이미지를 당겨와 실행

필요에 따라 VPC 설정이나 추가 IAM 정책을 lambda_exec.tf 에 확장해 주세요.
