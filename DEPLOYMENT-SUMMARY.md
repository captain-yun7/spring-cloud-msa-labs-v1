# Spring Cloud MSA → EKS 배포 전체 구현 과정 정리

## 📋 **전체 구현 과정**

### **1단계: 기존 아키텍처 분석**
- **Spring Cloud MSA 구조**: API Gateway, Eureka Server, Config Server + 5개 비즈니스 서비스
- **로컬 환경**: Docker Compose 기반 실행
- **설정 관리**: Spring Cloud Config Server 중앙집중식

### **2단계: EKS 인프라 구축**
```bash
# EKS 클러스터 생성
eksctl create cluster --name yjs-spring-cloud-msa-cluster --region ap-northeast-2

# ECR 리포지토리 생성
./scripts/01-create-ecr-repositories.sh

# Docker 이미지 빌드 & 푸시  
./scripts/02-build-and-push-images.sh
```

### **3단계: Kubernetes 매니페스트 작성**
- **Infrastructure**: MySQL, RabbitMQ, Zipkin
- **Spring Cloud Services**: 각 마이크로서비스별 Deployment/Service
- **Network**: Ingress, LoadBalancer 설정

### **4단계: Config Server → ConfigMap/Secret 전환**
- **문제**: Config Server 의존성 제거 필요
- **해결**: 
  - 각 서비스별 ConfigMap 생성
  - 민감정보는 Secret으로 분리
  - 환경변수 방식으로 주입

### **5단계: 리소스 최적화 및 스케일링**
- **문제**: t3.medium 노드로 리소스 부족
- **해결**: t3.xlarge 노드그룹 추가 (4 CPU, 16GB RAM)

### **6단계: 이미지 캐시 이슈 해결**
- **문제**: Config Server 참조가 남아있는 이미지
- **해결**: v2 태그로 새 이미지 빌드 + 환경변수 강화

### **7단계: RabbitMQ 이벤트 설정 완성**
- **문제**: 이벤트 기반 통신 설정 누락
- **해결**: 완전한 큐/라우팅 키 설정 추가

---

## 🔧 **주요 트러블슈팅 해결방법**

### **1. Config Server 의존성 제거**

**🚨 문제:**
```
Unable to load config data from 'configserver:http://config-server:8888'
```

**✅ 해결방법:**
```yaml
# 1. application.yml 수정
spring:
  config:
    import: "${SPRING_CONFIG_IMPORT:}"

# 2. K8s 환경변수 설정
env:
- name: SPRING_CONFIG_IMPORT
  value: ""
- name: SPRING_CLOUD_CONFIG_ENABLED
  value: "false"
- name: SPRING_CLOUD_CONFIG_IMPORT_CHECK_ENABLED
  value: "false"
```

### **2. 리소스 부족 문제**

**🚨 문제:**
```
0/2 nodes are available: 2 Insufficient cpu, 2 Insufficient memory
```

**✅ 해결방법:**
```bash
# 새 노드그룹 생성
eksctl create nodegroup --cluster=yjs-spring-cloud-msa-cluster \
  --name=spring-cloud-workers-xlarge --node-type=t3.xlarge \
  --nodes=2 --nodes-min=2 --nodes-max=4

# 리소스 최적화
resources:
  requests:
    memory: "512Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

### **3. 이미지 캐시 문제**

**🚨 문제:**
- 새로운 설정이 적용된 이미지가 pull되지 않음

**✅ 해결방법:**
```yaml
# 1. 새 태그로 이미지 빌드
./scripts/02-build-and-push-images.sh ap-northeast-2 v2

# 2. imagePullPolicy 설정
spec:
  containers:
  - name: service-name
    image: repo/service:v2
    imagePullPolicy: Always
```

### **4. RabbitMQ 설정 누락**

**🚨 문제:**
```
Could not resolve placeholder 'order.event.exchange'
```

**✅ 해결방법:**
```yaml
# ConfigMap에 이벤트 설정 추가
data:
  order.event.exchange: "order.exchange"
  order.event.queue.payment-request: "order.payment.request.queue"
  order.event.routing-key.payment-request: "order.payment.request"
  # ... 기타 큐/라우팅 키 설정
```

### **5. 메모리 부족 에러**

**🚨 문제:**
```
fixed memory regions require 636817K which is greater than 512M available
```

**✅ 해결방법:**
```yaml
# 메모리 한계 상향 조정
resources:
  limits:
    memory: "1Gi"  # 512Mi → 1Gi로 증가
```

---

## 🎯 **핵심 성공 요소**

### **1. 단계별 점진적 접근**
- Config Server 제거 → 리소스 최적화 → 이미지 갱신 → 설정 완성

### **2. 적절한 리소스 관리**  
- EKS 노드 스케일링으로 근본적 해결
- 서비스별 리소스 요구사항 최적화

### **3. 현대적 설정 관리**
- Config Server → ConfigMap/Secret 전환
- 환경변수 기반 설정 주입

### **4. 체계적인 문제 해결**
- 로그 분석 → 원인 파악 → 단계별 해결 → 검증

---

## 📊 **최종 결과**

### **성공적으로 배포된 서비스:**
- ✅ Eureka Server (1 pod)
- ✅ API Gateway (2 pods) 
- ✅ User Service (2 pods)
- ✅ Product Service (2 pods)
- ✅ Order Service (1 pod)
- ✅ Payment Service (2 pods)
- ✅ Notification Service (1 pod)
- ✅ Infrastructure Services (MySQL, RabbitMQ, Zipkin)

### **인프라 구성:**
- **EKS Cluster**: 4노드 (t3.medium 2개 + t3.xlarge 2개)
- **총 리소스**: 10 CPU, 22GB RAM
- **설정 관리**: ConfigMap 7개 + Secret 1개
- **네트워킹**: 완전한 서비스 메시 구성

### **아키텍처 다이어그램:**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Gateway   │────│  Eureka Server  │────│   User Service  │
│    (2 pods)     │    │    (1 pod)      │    │    (2 pods)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │ Product Service │────│  Order Service  │
         │              │    (2 pods)     │    │    (1 pod)      │
         │              └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐    ┌─────────────────┐
         └──────────────│ Payment Service │────│Notification Svc │
                        │    (2 pods)     │    │    (1 pod)      │
                        └─────────────────┘    └─────────────────┘
                                 │
                ┌────────────────────────────────────────────────┐
                │         Infrastructure Services                │
                │  MySQL │ RabbitMQ │ Zipkin │ ConfigMap/Secret  │
                └────────────────────────────────────────────────┘
```

### **주요 기술 스택:**
- **Container Platform**: Amazon EKS (Kubernetes 1.31)
- **Service Mesh**: Spring Cloud (Eureka, Gateway)
- **Message Queue**: RabbitMQ
- **Database**: MySQL
- **Monitoring**: Zipkin (Distributed Tracing)
- **Configuration**: Kubernetes ConfigMap/Secret
- **Container Registry**: Amazon ECR

---

## 🚀 **다음 단계 가이드**

### **1. 외부 접근 설정**
```bash
# LoadBalancer 타입으로 API Gateway 노출
kubectl patch svc api-gateway-service -n spring-cloud-msa \
  -p '{"spec": {"type": "LoadBalancer"}}'

# Ingress 설정 (선택사항)
kubectl apply -f k8s/network/ingress.yml
```

### **2. 모니터링 강화**
```bash
# Prometheus & Grafana 설치
helm install prometheus prometheus-community/kube-prometheus-stack

# 서비스 메트릭 확인
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090
```

### **3. 보안 강화**
- Network Policy 적용
- RBAC 설정
- Pod Security Standards 적용

### **4. CI/CD 파이프라인 구축**
- GitHub Actions와 EKS 연동
- ArgoCD를 통한 GitOps 구현

---

## 📚 **참고 자료**

- [EKS 공식 문서](https://docs.aws.amazon.com/eks/)
- [Spring Cloud 가이드](https://spring.io/projects/spring-cloud)
- [Kubernetes 공식 문서](https://kubernetes.io/docs/)
- [eksctl 사용법](https://eksctl.io/)

---

**🎉 Spring Cloud 마이크로서비스가 EKS에서 완전히 성공적으로 실행 중입니다!**

*생성일: 2025-09-10*  
*작성자: Claude Code*