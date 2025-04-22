# 🚀 Chapter 2: 마이크로서비스 기본 기능 구현

## 🎯 목표

이 챕터에서는 **각 마이크로서비스의 기본 기능을 구현**하고 **프론트엔드와 연동**하여 미니 쇼핑몰의 핵심 기능을 완성합니다.  
학습자는 **MSA 아키텍처에서 각 서비스의 역할과 책임**을 이해하고 **기본적인 서비스 구성 방법**을 익히게 됩니다.

---

## 📚 학습 내용

1. 🧩 각 마이크로서비스별 핵심 기능 구현 (MSA 학습 목적에 맞게 최소한 기능만 구현)
2. 📊 각 서비스별 가데이터 생성
3. 🔐 Spring Security를 활용한 회원 기능 구현
4. 🔄 프론트엔드와 백엔드 API 연동

---

## 🔨 작업 내역

### 📦 백엔드: 각 서비스별 기본 기능 구현

#### 🙋‍♂️ User Service
- 회원 조회 API 구현
- 회원 가입 기능 구현 (Spring Security로 구현)

#### 🛒 Product Service
- 상품 조회 API 구현

#### 📝 Order Service
- 주문 조회 API 구현

#### 💳 Payment Service
- 결제 조회 API 구현

#### 🔔 Notification Service
- 알림 조회 API 구현

#### 📁 프로젝트 구조

```
backend/
├─ infra/               # 컨테이너 기반 인프라 구성 요소
│  └─ docker-compose.yml
├─ notification-service 
│  ├─ controller/       # REST API 컨트롤러
│  ├─ service/          # 비즈니스 로직
│  ├─ repository/       # 데이터 액세스 계층
│  ├─ model/            # 엔티티 및 DTO
│  └─ config/           # 설정 클래스
├─ order-service
│  ├─ controller/
│  ├─ service/
│  ├─ repository/
│  ├─ model/
│  └─ config/
├─ payment-service
│  ├─ controller/
│  ├─ service/
│  ├─ repository/
│  ├─ model/
│  └─ config/
├─ product-service
│  ├─ controller/
│  ├─ service/
│  ├─ repository/
│  ├─ model/
│  └─ config/
└─ user-service
   ├─ controller/
   ├─ service/
   ├─ repository/
   ├─ model/
   ├─ config/
   └─ security/          # Spring Security 관련 클래스
```

---

### 💻 프론트엔드: API 테스트 데이터로 페이지 생성

#### 📱 주요 페이지 구현

- 로그인/회원가입 페이지
- 상품 목록 페이지
- 상품 상세 페이지
- 주문 내역 페이지
- 결제 내역 페이지
- 알림 페이지

#### 🔌 API 연동

- 테스트 데이터를 활용한 UI 구현
- API 응답 처리 및 오류 핸들링

#### 📁 프로젝트 구조

```
frontend/
├─ public/              # 정적 리소스 (favicon, 이미지 등)
├─ src/                 
│  ├─ components/       # 재사용 가능한 컴포넌트
│  ├─ pages/            # 페이지 컴포넌트
│  ├─ services/         # API 통신 관련 서비스
│  ├─ hooks/            # 커스텀 훅
│  ├─ context/          # React Context
│  ├─ types/            # TypeScript 타입 정의
│  ├─ utils/            # 유틸리티 함수
│  ├─ App.tsx           # 메인 컴포넌트
│  └─ main.tsx          # React 진입점
├─ index.html           # HTML 템플릿
├─ package.json         # 의존성 및 스크립트
└─ vite.config.ts       # Vite 설정
```

---

## ▶️ 실행 방법

### 1. 📦 백엔드 실행

#### 🔹 MySQL 컨테이너 실행

```bash
cd backend/infra
docker-compose up -d
```

#### 🔹 각 마이크로서비스 실행

```bash
./gradlew bootRun
```

> IntelliJ 또는 VSCode에서 각각 실행해도 OK

---

### 2. 💻 프론트엔드 실행

```bash
cd frontend
npm install
npm run dev
```

> 기본 실행 포트는 `localhost:5173`

---