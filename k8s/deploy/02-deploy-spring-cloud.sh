#!/bin/bash

# Spring Cloud 서비스 배포 스크립트
# ConfigMap/Secret → Eureka → 비즈니스 서비스들 순차 배포

set -e

echo "🚀 Spring Cloud 서비스 배포를 시작합니다..."

# ECR 이미지는 이미 설정되어 있음
echo "🔄 ECR 이미지 확인 완료"

# 1. ConfigMaps and Secrets 배포
echo "⚙️ ConfigMaps and Secrets 배포 중..."
./00-deploy-configmaps-secrets.sh

# 2. Eureka Server 배포
echo "🗺️ Eureka Server 배포 중..."
kubectl apply -f ../spring-cloud/eureka-server.yml
echo "Eureka Server 배포 완료. 준비 상태 확인 중..."
kubectl wait --for=condition=ready pod -l app=eureka-server -n spring-cloud-msa --timeout=300s

# 3. Core Services 배포 (동시 배포)
echo "💼 Core Services 배포 중..."
kubectl apply -f ../spring-cloud/user-service.yml
kubectl apply -f ../spring-cloud/product-service.yml
kubectl apply -f ../spring-cloud/payment-service.yml
kubectl apply -f ../spring-cloud/notification-service.yml

echo "Core Services 배포 완료. 준비 상태 확인 중..."
kubectl wait --for=condition=ready pod -l 'app in (user-service,product-service,payment-service,notification-service)' -n spring-cloud-msa --timeout=600s

# 4. Order Service 배포 (다른 서비스들에 의존)
echo "📋 Order Service 배포 중..."
kubectl apply -f ../spring-cloud/order-service.yml
echo "Order Service 배포 완료. 준비 상태 확인 중..."
kubectl wait --for=condition=ready pod -l app=order-service -n spring-cloud-msa --timeout=300s

# 5. API Gateway 배포 (모든 서비스 준비 완료 후)
echo "🌐 API Gateway 배포 중..."
kubectl apply -f ../spring-cloud/api-gateway.yml
echo "API Gateway 배포 완료. 준비 상태 확인 중..."
kubectl wait --for=condition=ready pod -l app=api-gateway -n spring-cloud-msa --timeout=300s

echo "✅ 모든 Spring Cloud 서비스 배포 완료!"
echo ""
echo "📊 서비스 상태 확인:"
kubectl get pods -n spring-cloud-msa -l 'app in (eureka-server,user-service,product-service,payment-service,notification-service,order-service,api-gateway)'
echo ""
echo "🌐 서비스 엔드포인트:"
kubectl get svc -n spring-cloud-msa