# EKS 배포 스크립트

EKS에 Spring Cloud MSA 프로젝트를 배포하기 위한 스크립트 모음입니다.

## 사용법

### 1. ECR 리포지토리 생성
```bash
./01-create-ecr-repositories.sh [region]
```

**기능:**
- Spring Cloud MSA 프로젝트의 모든 서비스용 ECR 리포지토리 생성
- 라이프사이클 정책 자동 설정 (최대 10개 이미지 보관)
- 이미지 스캔 활성화
- AES256 암호화 설정

**예시:**
```bash
# 기본 리전 (ap-northeast-2) 사용
./01-create-ecr-repositories.sh

# 특정 리전 사용
./01-create-ecr-repositories.sh us-west-2
```

### 2. Docker 이미지 빌드 및 푸시
```bash
./02-build-and-push-images.sh [region] [tag]
```

**기능:**
- 모든 Spring Boot 서비스의 Docker 이미지 빌드
- ECR에 이미지 자동 푸시
- 빌드 상태 및 푸시 결과 표시
- 이미지 크기 정보 제공

**예시:**
```bash
# 기본 설정 (ap-northeast-2, latest 태그)
./02-build-and-push-images.sh

# 특정 리전과 태그 사용
./02-build-and-push-images.sh ap-northeast-2 v1.0.0
```

## 전제 조건

### AWS 설정
- AWS CLI 설치 및 설정
- ECR 권한이 있는 AWS 자격증명
- Docker 설치 및 실행 중

### 프로젝트 구조
```
spring-cloud-msa-labs-v1/
├── backend/
│   ├── api-gateway/
│   ├── config-server/
│   ├── eureka-server/
│   ├── user-service/
│   ├── product-service/
│   ├── order-service/
│   ├── payment-service/
│   └── notification-service/
└── scripts/
    ├── 01-create-ecr-repositories.sh
    └── 02-build-and-push-images.sh
```

### 3. EKS 클러스터 생성 전 필수 도구 확인
```bash
./05-check-prerequisites.sh
```

**기능:**
- AWS CLI, eksctl, kubectl, helm 설치 확인
- AWS 자격증명 확인
- SSH 키 확인
- 버전 정보 표시

### 4. EKS 클러스터 생성
```bash
./03-create-eks-cluster.sh
```

**기능:**
- EKS 클러스터 및 워커 노드 생성
- 네임스페이스 생성
- ECR 액세스용 시크릿 생성

**클러스터 설정:**
- 클러스터명: spring-cloud-msa-cluster
- 리전: ap-northeast-2
- 노드 타입: t3.medium
- 노드 수: 3
- Kubernetes 버전: 1.31

### 5. EKS 클러스터 삭제
```bash
./04-delete-eks-cluster.sh
```

**기능:**
- 확인 프롬프트 제공
- 애플리케이션 리소스 정리
- EKS 클러스터 완전 삭제

## 서비스 목록

스크립트가 처리하는 서비스들:
- api-gateway
- config-server
- eureka-server  
- user-service
- product-service
- order-service
- payment-service
- notification-service

## 문제 해결

### ECR 로그인 실패
```bash
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin {ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com
```

### Gradle 권한 문제
```bash
find backend/ -name "gradlew" -exec chmod +x {} \;
```

### Docker Build 실패
각 서비스 디렉토리에서 개별적으로 빌드 테스트:
```bash
cd backend/user-service
./gradlew bootBuildImage --imageName=test-image
```

## 배포 순서

1. **ECR 리포지토리 생성**
   ```bash
   ./01-create-ecr-repositories.sh
   ```

2. **Docker 이미지 빌드 및 푸시**
   ```bash
   ./02-build-and-push-images.sh
   ```

3. **필수 도구 확인**
   ```bash
   ./05-check-prerequisites.sh
   ```

4. **EKS 클러스터 생성**
   ```bash
   ./03-create-eks-cluster.sh
   ```

5. **Kubernetes 매니페스트 배포** (다음 단계)
   - 인프라 서비스 배포 (MySQL, RabbitMQ, Zipkin)
   - Spring Cloud 서비스 배포
   - Ingress 및 Service 설정

## 다음 단계

1. Kubernetes 매니페스트 파일 생성
2. 인프라 서비스 배포 (MySQL, RabbitMQ, Zipkin)
3. Spring Cloud 서비스 배포 (Config Server → Eureka → 애플리케이션 서비스들)
4. Ingress 설정 및 외부 액세스 구성