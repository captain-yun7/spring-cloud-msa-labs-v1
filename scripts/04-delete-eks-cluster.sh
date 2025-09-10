#!/bin/bash

# EKS 클러스터 삭제 스크립트

set -e

# 변수 설정
CLUSTER_NAME="spring-cloud-msa-cluster"
REGION="ap-northeast-2"

echo "⚠️  EKS 클러스터 삭제를 시작합니다..."
echo "클러스터명: $CLUSTER_NAME"
echo "리전: $REGION"

# 확인 메시지
read -p "정말로 클러스터를 삭제하시겠습니까? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "❌ 클러스터 삭제가 취소되었습니다."
    exit 0
fi

# 1. 애플리케이션 리소스 삭제
echo "🗑️  애플리케이션 리소스 삭제 중..."
kubectl delete namespace spring-cloud-msa --ignore-not-found=true

# 2. EKS 클러스터 삭제
echo "🗑️  EKS 클러스터 삭제 중... (약 10-15분 소요)"
eksctl delete cluster --name $CLUSTER_NAME --region $REGION

echo "✅ EKS 클러스터 삭제가 완료되었습니다!"