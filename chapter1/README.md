# Chapter 1: 미니 쇼핑몰 프로젝트 구축

## 📌 목표

이 챕터에서는 **Spring Boot 기반 마이크로서비스 백엔드**와 **React 기반 프론트엔드 프로젝트**의 초기 설정을 진행합니다.  
학습자는 MSA 구조와 프론트엔드 클라이언트 개발의 기반을 익힐 수 있습니다.

---

## 🎯 학습 내용

1. 마이크로서비스 구조 설계 및 초기화
2. 서비스 간 독립 실행 설정
3. React 프로젝트 초기화 (TypeScript 기반)

---

## 🛠️ 작업 내역

### 1. 백엔드: 마이크로서비스 초기화

초기화한 서비스 목록:

- `user-service`
- `product-service`
- `order-service`
- `payment-service`
- `notification-service`

#### 🔧 공통 의존성 (모든 서비스에 공통 적용)

```groovy
implementation 'org.springframework.boot:spring-boot-starter-web'         // REST API
implementation 'org.springframework.boot:spring-boot-starter-actuator'    // 헬스체크, 모니터링
implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:2.1.0'  // Swagger(OpenAPI 문서화)
```

### 2. 프론트엔드 : React 기반 프로젝트 초기화