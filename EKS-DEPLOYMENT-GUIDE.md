# EKS MSA 프로젝트 배포 가이드

Spring Cloud MSA 프로젝트를 AWS EKS에 배포하기 위한 완전한 가이드

## 📋 전체 작업 체크리스트

### ✅ 1. 사전 준비 (완료)
- [x] ECR 리포지토리 생성
- [x] Docker 이미지 빌드 및 푸시
- [x] EKS 클러스터 생성 스크립트

### 🔄 2. EKS 클러스터 생성
```bash
./scripts/05-check-prerequisites.sh  # 필수 도구 확인
./scripts/03-create-eks-cluster.sh   # 클러스터 생성
```

### 📦 3. 인프라 서비스 배포
배포 순서 (의존성 고려):
1. **RabbitMQ** - 메시지 브로커
2. **Zipkin** - 분산 트레이싱
3. **MySQL** - 임시 데이터베이스 (RDS 전환 예정)

### 🚀 4. Spring Cloud 서비스 배포
의존성 순서에 따른 배포:
1. **Config Server** - 중앙 설정 관리
2. **Eureka Server** - 서비스 디스커버리
3. **Core Services** - User, Product, Payment, Notification
4. **Order Service** - Saga 오케스트레이터
5. **API Gateway** - 외부 접점

### 🌐 5. 네트워크 설정
- Service 리소스 생성 (ClusterIP/LoadBalancer)
- Ingress 설정 (외부 접근)

## 📁 생성할 디렉토리 구조

```
k8s/
├── infrastructure/
│   ├── rabbitmq.yml
│   ├── zipkin.yml
│   └── mysql.yml
├── spring-cloud/
│   ├── config-server.yml
│   ├── eureka-server.yml
│   ├── user-service.yml
│   ├── product-service.yml
│   ├── payment-service.yml
│   ├── notification-service.yml
│   ├── order-service.yml
│   └── api-gateway.yml
├── network/
│   ├── services.yml
│   └── ingress.yml
└── deploy/
    ├── 01-deploy-infrastructure.sh
    ├── 02-deploy-spring-cloud.sh
    └── 03-deploy-network.sh
```

## ⚙️ 주요 설정 포인트

### 환경 변수
- **DATABASE_URL**: MySQL 연결 정보
- **RABBITMQ_HOST**: 메시지 브로커 연결
- **EUREKA_SERVER_URL**: 서비스 디스커버리
- **CONFIG_SERVER_URL**: 중앙 설정 서버

### 네트워크 통신
- **클러스터 내부**: Service DNS 이름 사용
- **외부 접근**: Ingress를 통한 API Gateway
- **헬스체크**: `/actuator/health` 엔드포인트

### 리소스 할당
- **Config/Eureka**: 512Mi memory, 0.5 CPU
- **Business Services**: 1Gi memory, 0.5 CPU  
- **API Gateway**: 1Gi memory, 1 CPU

## 🔧 다음 작업 단계

1. **인프라 매니페스트 작성** - RabbitMQ, Zipkin, MySQL
2. **Spring Cloud 매니페스트 작성** - 각 서비스별 Deployment/Service
3. **ConfigMap 설정** - 환경별 설정 관리
4. **배포 스크립트 작성** - 순차 배포 자동화
5. **Ingress 설정** - 외부 접근 구성
6. **헬스체크 및 모니터링** - 배포 검증

## 🎯 최종 목표

- ✅ 모든 서비스가 EKS에서 정상 동작
- ✅ 서비스 간 통신 정상 (Eureka + Feign)
- ✅ 이벤트 기반 통신 정상 (RabbitMQ)
- ✅ 외부에서 API Gateway를 통한 접근 가능
- ✅ 분산 트레이싱 데이터 수집 (Zipkin)

## 📝 참고사항

- **포트 정보**: API Gateway(8080), Eureka(8761), Config(8888)
- **네임스페이스**: `spring-cloud-msa`
- **이미지 레지스트리**: `{ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com`
- **배포 검증**: `kubectl get pods -n spring-cloud-msa`