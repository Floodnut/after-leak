# after-leak

## What is After-leak?
`After-leak`은 개인이 직접 실험 환경을 운용할 수 있도록 보조하는 프로젝트 입니다.
손 쉬운 사용을 통해 클라우드(AWS) 상에서 사회적 실험을 직접 수행해볼 수 있습니다.

## Depends-on
- 디스코드 서버 및 채널 웹훅
- Github 조직
- AWS 계정 및 액세스/시크릿 키

## How to use

1. Install Terraform

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

2. 디스코드 채널과 웹훅을 만드세요.
- 웹훅 uri를 람다의 환경변수 혹은 `WEBHOOK_URL`에 적용하세요.
```python
# src/lambda/webhook.py
# ...
WEBHOOK_URL = WEBHOOK_BASE_URL + "__webhook_uri__"
# ...
```

3. 실험 샌드박스 환경을 설정합니다.
- `src/sandbox` 하위에 AWS 조직 계정과 조직 하위의 리소스(e.g. ec2, rds ...) 를 설정하세요.
- 기본 값은 ec2 인스턴스가 적용되어 있습니다.

4. 추가 환경 변수를 등록하세요.
```bash
AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY_ID ...
```

5. Plan, Up!
```bash
terraform init
terraform apply
```
