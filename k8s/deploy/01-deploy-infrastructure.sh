#!/bin/bash

# 인프라 서비스 배포 스크립트
# MySQL, RabbitMQ, Zipkin 순차 배포

set -e

echo "🚀 인프라 서비스 배포를 시작합니다..."

# 1. MySQL 배포
echo "💾 MySQL 배포 중..."
kubectl apply -f ../infrastructure/mysql.yml
echo "MySQL 배포 완료. 준비 상태 확인 중..."
kubectl wait --for=condition=ready pod -l app=mysql -n spring-cloud-msa --timeout=300s

# 2. RabbitMQ 배포
echo "🐰 RabbitMQ 배포 중..."
kubectl apply -f ../infrastructure/rabbitmq.yml
echo "RabbitMQ 배포 완료. 준비 상태 확인 중..."
kubectl wait --for=condition=ready pod -l app=rabbitmq -n spring-cloud-msa --timeout=300s

# 3. Zipkin 배포
echo "🔍 Zipkin 배포 중..."
kubectl apply -f ../infrastructure/zipkin.yml
echo "Zipkin 배포 완료. 준비 상태 확인 중..."
kubectl wait --for=condition=ready pod -l app=zipkin -n spring-cloud-msa --timeout=300s

echo "✅ 모든 인프라 서비스 배포 완료!"
echo ""
echo "📊 서비스 상태 확인:"
kubectl get pods -n spring-cloud-msa -l 'app in (mysql,rabbitmq,zipkin)'
echo ""
echo "🌐 서비스 엔드포인트:"
kubectl get svc -n spring-cloud-msa -l 'app in (mysql,rabbitmq,zipkin)'