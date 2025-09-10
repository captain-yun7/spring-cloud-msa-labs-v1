# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Spring Cloud microservices learning project implementing an e-commerce platform with the following architecture:

- **API Gateway** (port 8080) - Routes requests and handles JWT authentication
- **Eureka Server** (port 8761) - Service discovery
- **Config Server** (port 8888) - Centralized configuration management
- **User Service** (port 8081) - User management and authentication
- **Product Service** (port 8082) - Product catalog and inventory management
- **Order Service** (port 8083) - Order processing and saga orchestration
- **Payment Service** (port 8085) - Payment processing
- **Notification Service** (port 8084) - Event-driven notifications
- **Frontend** (Next.js) - React-based shopping mall UI

## Key Architecture Patterns

### Event-Driven Saga Pattern
The system implements the Saga pattern for distributed transactions using RabbitMQ:
- **Order Service** acts as the saga orchestrator
- Events flow through RabbitMQ exchanges with routing keys
- Compensation logic handles failures (order cancellation, inventory restoration)
- Key event types: OrderCreated, PaymentCompleted/Failed, InventoryFailed

### Service Communication
- **Synchronous**: Feign clients for direct service-to-service calls
- **Asynchronous**: RabbitMQ for event-driven communication
- **Service Discovery**: Eureka for dynamic service registration/discovery
- **Configuration**: Spring Cloud Config for centralized configuration

## Development Commands

### Backend Services (Gradle)
Each microservice uses Gradle as the build tool:

```bash
# Build a service
cd backend/[service-name]
./gradlew build

# Run tests
./gradlew test

# Build Docker image
./gradlew bootBuildImage

# Clean build artifacts
./gradlew clean

# Run locally (requires dependencies)
./gradlew bootRun
```

### Frontend (Next.js)
```bash
cd frontend/mini-shopping-mall-frontend

# Development server
npm run dev

# Production build
npm run build

# Start production server
npm start

# Lint code
npm run lint
```

### Docker Deployment
```bash
# Start all infrastructure and services
docker-compose up -d

# Start only infrastructure (MySQL, RabbitMQ, Zipkin)
docker-compose -f backend/infra/docker-compose.yml up -d

# View logs
docker-compose logs -f [service-name]

# Stop all services
docker-compose down
```

## Service Dependencies

Services must start in this order:
1. Infrastructure: MySQL, RabbitMQ, Zipkin
2. Config Server
3. Eureka Server  
4. Core Services: User, Product, Payment, Notification
5. Order Service (depends on User + Product services)
6. API Gateway (depends on all backend services)

## Configuration Management

- **Global config**: `backend/config-repo/application.yml`
- **Service-specific**: `backend/config-repo/[service-name].yml`
- **Environment profiles**: `application-dev.yml`, `application-docker.yml`, `application-prod.yml`

## Database Setup

The system uses MySQL with separate databases per service:
- Database initialization scripts: `backend/infra/mysql/init/`
- Database per service pattern: `user_service_db`, `product_service_db`, etc.
- Connection details configured via Spring Cloud Config

## Event System Configuration

RabbitMQ configuration is defined in each service's `RabbitConfig.java`:
- **Exchange**: Topic exchange for routing events
- **Queues**: Durable queues for each event type
- **Routing Keys**: Pattern-based message routing
- **Message Converter**: Jackson2JsonMessageConverter for JSON serialization

## Monitoring and Tracing

- **Distributed Tracing**: Zipkin integration enabled across all services
- **Health Checks**: Spring Actuator endpoints exposed on `/actuator/health`
- **Service Discovery**: Eureka dashboard available at http://localhost:8761

## Testing

Tests are located in `src/test/java` for each service. Run tests using:
```bash
./gradlew test
```

## Common Development Patterns

- All services extend Spring Boot with Spring Cloud dependencies
- JWT authentication handled by API Gateway with token validation
- Database entities use JPA with automatic DDL updates
- Event publishing/consuming uses RabbitMQ with JSON message format
- Error handling includes compensation logic for distributed transactions

## Port Reference

- API Gateway: 8080
- User Service: 8081  
- Product Service: 8082
- Order Service: 8083
- Notification Service: 8084
- Payment Service: 8085
- Config Server: 8888
- Eureka Server: 8761
- MySQL: 3307 (external), 3306 (internal)
- RabbitMQ: 5672 (AMQP), 15672 (Management UI)
- Zipkin: 9411
- Frontend: 3000