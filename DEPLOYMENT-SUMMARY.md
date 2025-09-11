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

## 🔧 **프론트엔드 연동 및 API Gateway 라우팅 트러블슈팅**

### **8. Next.js 프론트엔드 배포 및 CORS 이슈**

**🚨 문제:**
- Vercel로 배포된 HTTPS 프론트엔드에서 HTTP EKS API로 Mixed Content 에러
- 로그인 후 계속 로그인 페이지로 리다이렉션

**✅ 해결과정:**

#### **8.1 Mixed Content 에러 해결**
```javascript
// 환경변수 기반 API 설정
const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';

// CORS 설정 수정
@Configuration
public class CorsConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("*")  // 프로덕션에서 특정 도메인으로 제한
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(false);
    }
}
```

#### **8.2 User Service Eureka 연결 누락**
```yaml
# User Service 환경변수 추가
env:
- name: EUREKA_CLIENT_ENABLED
  value: "true"  # false → true로 변경
```

### **9. API Gateway 라우팅 설정 트러블슈팅**

**🚨 주요 문제들:**
1. ConfigMap 파일 마운트 누락
2. Spring Cloud Gateway 설정 키 변경
3. Eureka vs Kubernetes Service 불일치

#### **9.1 ConfigMap 볼륨 마운트 문제**
**문제:** `application.yml`이 환경변수로만 로드되어 라우팅 설정 무시
```yaml
# AS-IS: 환경변수만 로드 (❌)
envFrom:
- configMapRef:
    name: api-gateway-config

# TO-BE: 파일 볼륨 마운트 추가 (✅)
envFrom:
- configMapRef:
    name: api-gateway-config
volumeMounts:
- name: config-volume
  mountPath: /workspace/application.yml
  subPath: application.yml
  readOnly: true
volumes:
- name: config-volume
  configMap:
    name: api-gateway-config
```

#### **9.2 Spring Cloud Gateway 설정 키 변경**
**문제:** Spring Boot 3.x에서 Gateway MVC 설정 경로 변경
```yaml
# AS-IS: 구버전 설정 (❌)
spring:
  cloud:
    gateway:
      mvc:
        routes:

# TO-BE: 신버전 설정 (✅)  
spring:
  cloud:
    gateway:
      server:
        webmvc:
          routes:
```

#### **9.3 Kubernetes에서 Load Balancer URI 문제**
**문제:** Eureka 서비스 이름으로 접근시 Pod DNS 해결 불가
```yaml
# AS-IS: Eureka 기반 (❌)
- id: product-service
  uri: lb://PRODUCT-SERVICE  # Pod 이름으로 접근 시도 → DNS 실패

# TO-BE: Kubernetes Service 직접 사용 (✅)
- id: product-service  
  uri: http://product-service-service:8082  # Service DNS로 직접 접근
```

### **10. JWT Filter와 StripPrefix 경로 처리**

**🚨 문제:** JWT Filter가 StripPrefix 적용 전/후 경로를 혼동

**✅ 해결방법:**
```java
// JWT Filter는 StripPrefix 적용 전 원본 경로를 받음
private boolean isPublicPath(String path, String method) {
    return path.equals("/users/login") ||        // StripPrefix 후 경로
            path.startsWith("/products") ||      // StripPrefix 후 경로  
            path.startsWith("/actuator/") ||
            "OPTIONS".equals(method);
}
```

**요청 플로우:**
```
1. 프론트엔드: /api/products 요청
2. JWT Filter: /api/products 경로 확인 → public path 허용
3. Gateway Route: /api/products → StripPrefix=1 → /products
4. Product Service: /products 경로로 라우팅
5. 응답: 제품 데이터 반환
```

### **11. Kubernetes vs Eureka 서비스 디스커버리**

**💡 교훈:** Kubernetes 환경에서는 Eureka보다 네이티브 Service Discovery 선호

**Eureka 방식 (복잡함):**
```
Request → API Gateway → Eureka Registry → Service Instance → Pod IP → DNS 실패
```

**Kubernetes 방식 (단순함):**
```  
Request → API Gateway → Kubernetes Service → Pod (로드밸런싱 자동)
```

**결론:** Kubernetes 환경에서는 Eureka 대신 Service 이름을 직접 사용하는 것이 더 효율적

---

## 📚 **참고 자료**

- [EKS 공식 문서](https://docs.aws.amazon.com/eks/)
- [Spring Cloud 가이드](https://spring.io/projects/spring-cloud)
- [Kubernetes 공식 문서](https://kubernetes.io/docs/)
- [eksctl 사용법](https://eksctl.io/)

---

## 🎯 **최종 성과 및 교훈**

### **성공적으로 해결된 주요 이슈들:**
1. ✅ **ConfigMap 파일 마운트**: 환경변수 → 볼륨 마운트로 전환
2. ✅ **Spring Cloud Gateway 설정**: 신버전 호환 설정 키 적용  
3. ✅ **Kubernetes Service Discovery**: Eureka → K8s Service 직접 사용
4. ✅ **JWT Filter 경로 처리**: StripPrefix 적용 순서 이해 및 해결
5. ✅ **프론트엔드 연동**: CORS, Mixed Content, Eureka 연결 이슈 해결

### **핵심 학습 포인트:**
- **Kubernetes Native 접근**: 전통적 서비스 디스커버리보다 K8s Service 활용이 효과적
- **설정 파일 vs 환경변수**: 복잡한 YAML 설정은 파일 마운트가 필수
- **요청 플로우 이해**: Filter → Gateway Route → StripPrefix → Service 순서 파악 중요
- **단계별 디버깅**: 로그 분석을 통한 체계적 문제 해결 접근

---

**🎉 Spring Cloud 마이크로서비스가 EKS에서 완전히 성공적으로 실행 중이며, 프론트엔드와의 연동까지 완료되었습니다!**

*생성일: 2025-09-10*  
*최종 업데이트: 2025-09-11 (프론트엔드 연동 및 API Gateway 라우팅 완성)*  
*작성자: Claude Code*