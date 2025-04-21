# 데이터 초기화 서비스

이 서비스는 마이크로서비스 구조의 각 서비스 데이터베이스를 한 번에 초기화하는 도구입니다.
JSON 파일에서 데이터를 읽어 각 서비스의 파일 기반 H2 데이터베이스에 일괄 적재합니다.

## 기능

- 모든 서비스 데이터 초기화
- 특정 서비스 데이터만 초기화
- 모든 서비스 데이터 리셋 및 재초기화

## 사용 방법 1: 웹 인터페이스 (권장)

### 빌드 및 실행
```bash
./gradlew :backend:data-initializer-service:build
java -jar backend/data-initializer-service/build/libs/data-initializer.jar
```

### 웹 인터페이스 접속
웹 브라우저에서 다음 URL로 접속:
```
http://localhost:8090
```

### REST API 접근 (Postman 등으로 직접 호출)
```
# 모든 서비스 데이터 초기화
POST http://localhost:8090/api/data/initialize

# 모든 서비스 데이터 리셋 및 재초기화 
POST http://localhost:8090/api/data/reset

# 특정 서비스만 초기화
POST http://localhost:8090/api/data/initialize/{serviceName}
```

## 사용 방법 2: 명령행 실행

```bash
# 모든 서비스 데이터 초기화 (기존 데이터 유지)
java -jar backend/data-initializer-service/build/libs/data-initializer.jar initialize

# 모든 서비스 데이터 리셋 및 재초기화
java -jar backend/data-initializer-service/build/libs/data-initializer.jar reset

# 특정 서비스만 초기화
java -jar backend/data-initializer-service/build/libs/data-initializer.jar initialize-service user-service
```

## 데이터 파일 위치

모든 초기 데이터는 JSON 형식으로 다음 위치에 저장됩니다:

```
src/main/resources/data/
├── users.json
├── products.json
├── orders.json
├── payments.json
└── notifications.json
```

## API 문서 접근

Swagger UI를 사용하여 API 문서를 확인할 수 있습니다:
```
http://localhost:8090/swagger-ui.html
```

## 주의사항

- 이 서비스는 각 마이크로서비스가 실행 중이지 않을 때 사용하는 것이 좋습니다.
- 파일 기반 H2 데이터베이스를 사용하는 경우, 각 서비스 애플리케이션 설정의 파일 경로가 이 서비스의 설정과 일치해야 합니다. 