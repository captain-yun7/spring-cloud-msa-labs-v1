#!/bin/bash

# 네임스페이스 생성 (이미 존재하면 무시됨)
kubectl create namespace spring-cloud-msa --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying ConfigMaps and Secrets..."

# Common ConfigMap and Secret 배포
echo "Applying common configuration..."
kubectl apply -f ../secrets/common-secret.yml
kubectl apply -f ../configmaps/common-configmap.yml

# 각 서비스별 ConfigMap 배포
echo "Applying service-specific configurations..."
kubectl apply -f ../configmaps/user-service-configmap.yml
kubectl apply -f ../configmaps/product-service-configmap.yml
kubectl apply -f ../configmaps/order-service-configmap.yml
kubectl apply -f ../configmaps/payment-service-configmap.yml
kubectl apply -f ../configmaps/notification-service-configmap.yml
kubectl apply -f ../configmaps/api-gateway-configmap.yml
kubectl apply -f ../configmaps/eureka-server-configmap.yml

echo "ConfigMaps and Secrets deployed successfully!"

# 배포된 리소스 확인
echo ""
echo "Deployed ConfigMaps:"
kubectl get configmaps -n spring-cloud-msa | grep -E "(common-config|.*-service-config|eureka-server-config|api-gateway-config)"

echo ""
echo "Deployed Secrets:"
kubectl get secrets -n spring-cloud-msa | grep "common-secret"