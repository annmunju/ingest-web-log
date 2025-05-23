# EC2 Private EC2 Infrastructure as Code (IaC)

이 폴더는 사용자가 생성한 AMI를 이용하여 프라이빗 서브넷 내에서 EC2 인스턴스를 생성하기 위한 인프라스트럭처 코드(IaC)를 포함하고 있습니다. Terraform을 사용하여 AWS 리소스를 프로비저닝합니다.

## 구성 요소

1. **main.tf**: 
   - 프라이빗 서브넷 내에서 EC2 인스턴스를 생성합니다.
   - 사용자가 제공한 AMI ID를 사용하여 EC2 인스턴스를 설정합니다.
   - 필요한 보안 그룹 및 기타 리소스를 정의합니다.

2. **variables.tf**: 
   - Terraform에서 사용할 변수들을 정의합니다.
   - VPC ID, AWS 리전, 서브넷 ID, EC2 인스턴스 타입, EBS 볼륨 크기, SSH 키 이름, AMI ID 등을 설정할 수 있습니다.

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

## 주의 사항

- 이 코드는 AWS 리소스를 생성하므로, AWS 계정에서 요금이 발생할 수 있습니다.
- 사용이 끝난 후에는 `terraform destroy` 명령어를 사용하여 생성한 리소스를 삭제하는 것을 잊지 마세요.
