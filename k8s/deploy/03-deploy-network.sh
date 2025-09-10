#!/bin/bash

# 네트워크 리소스 배포 스크립트
# Service와 Ingress 설정 적용

set -e

echo "🌐 네트워크 리소스 배포를 시작합니다..."

# 1. External Services 배포
echo "🔌 External Services 배포 중..."
kubectl apply -f ../network/services.yml

# 2. Ingress 배포 (선택사항)
echo "🌐 Ingress 배포 중..."
if kubectl get ingressclass nginx &> /dev/null; then
    kubectl apply -f ../network/ingress.yml
    echo "Ingress 배포 완료"
else
    echo "⚠️  NGINX Ingress Controller가 설치되지 않음. Ingress 배포 건너뛰기"
    echo "설치 명령어: kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/aws/deploy.yaml"
fi

echo "✅ 네트워크 리소스 배포 완료!"
echo ""
echo "📊 LoadBalancer 서비스 상태:"
kubectl get svc -n spring-cloud-msa -o wide | grep LoadBalancer
echo ""
echo "📊 NodePort 서비스 상태:"
kubectl get svc -n spring-cloud-msa -o wide | grep NodePort
echo ""
echo "🌐 외부 접근 URL:"
EXTERNAL_IP=$(kubectl get svc api-gateway-external -n spring-cloud-msa -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "<pending>")
echo "API Gateway: http://$EXTERNAL_IP"
echo "Eureka Dashboard: http://<worker-node-ip>:30761"
echo "RabbitMQ Management: http://<worker-node-ip>:30672 (admin/admin123)"
echo "Zipkin UI: http://<worker-node-ip>:30411"