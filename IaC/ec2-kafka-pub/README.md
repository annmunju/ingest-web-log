# EC2 Kafka AMI Infrastructure as Code (IaC)

이 폴더는 AWS에서 퍼블릭 서브넷을 만들고 Apache Kafka를 EC2 인스턴스에 설치하기 위한 인프라스트럭처 코드(IaC)를 포함하고 있습니다. Terraform을 사용하여 AWS 리소스를 프로비저닝합니다.

## 구성 요소

1. **main.tf**: 
   - VPC에 퍼블릭 서브넷, 인터넷 게이트웨이, 라우팅 테이블, 카프카 EC2 인스턴스를 생성합니다.
   - 카프카를 실행하기 위한 보안 그룹을 설정합니다.
   - 최신 Amazon Linux 2 AMI를 사용하여 EC2 인스턴스를 생성하고, 카프카와 Zookeeper를 설치하는 사용자 데이터를 포함합니다.

2. **variables.tf**: 
   - Terraform에서 사용할 변수들을 정의합니다.
   - VPC ID, AWS 리전, 서브넷 ID, EC2 인스턴스 타입, EBS 볼륨 크기, SSH 키 이름 등을 설정할 수 있습니다.

## 사용 방법

1. **Terraform 설치**: Terraform이 설치되어 있어야 합니다. [Terraform 설치 가이드](https://www.terraform.io/downloads.html)를 참조하세요.

2. **변수 설정**: `variables.tf` 파일에서 필요한 변수를 설정합니다. VPC ID와 서브넷 ID는 AWS 콘솔에서 확인할 수 있습니다.

3. **Terraform 초기화**: 
   ```bash
   terraform init
   ```

4. **리소스 계획**: 
   ```bash
   terraform plan
   ```

5. **리소스 적용**: 
   ```bash
   terraform apply
   ```

6. **카프카 서버의 퍼블릭 IP 확인**: 
   Terraform이 완료되면, 카프카 서버의 퍼블릭 IP가 출력됩니다.

## 주의 사항

- 이 코드는 AWS 리소스를 생성하므로, AWS 계정에서 요금이 발생할 수 있습니다.
- 사용이 끝난 후에는 `terraform destroy` 명령어를 사용하여 생성한 리소스를 삭제하는 것을 잊지 마세요.
