#!/bin/bash

# EKS 클러스터 생성 스크립트
# Prerequisites: AWS CLI, eksctl, kubectl 설치 필요

set -e

# 변수 설정
CLUSTER_NAME="yjs-spring-cloud-msa-cluster"
REGION="ap-northeast-2"
NODE_GROUP_NAME="spring-cloud-workers"
NODE_TYPE="t3.medium"
NODE_COUNT=2
KUBERNETES_VERSION="1.31"

echo "🚀 EKS 클러스터 생성을 시작합니다..."
echo "클러스터명: $CLUSTER_NAME"
echo "리전: $REGION"
echo "노드 타입: $NODE_TYPE"
echo "노드 수: $NODE_COUNT"

# 1. EKS 클러스터 생성
echo "📦 EKS 클러스터 생성 중..."
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $REGION \
  --version $KUBERNETES_VERSION \
  --nodegroup-name $NODE_GROUP_NAME \
  --node-type $NODE_TYPE \
  --nodes $NODE_COUNT \
  --managed \
  --with-oidc \
  --full-ecr-access

# 2. kubectl 컨텍스트 업데이트
echo "🔧 kubectl 컨텍스트 업데이트 중..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# 3. 클러스터 상태 확인
echo "✅ 클러스터 상태 확인 중..."
kubectl get nodes
kubectl get svc

# 4. EBS CSI 드라이버 설치 (영구 볼륨용)
echo "💾 EBS CSI 드라이버 설치 중..."
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster $CLUSTER_NAME \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --override-existing-serviceaccounts

eksctl create addon --name aws-ebs-csi-driver --cluster $CLUSTER_NAME --service-account-role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/eksctl-$CLUSTER_NAME-addon-iamserviceaccount-kube-system-ebs-csi-controller-sa-Role1 --force

# 5. GP3 StorageClass 생성 (기본 StorageClass로 설정)
echo "🗂️ GP3 StorageClass 생성 중..."
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

# 6. 네임스페이스 생성
echo "📁 네임스페이스 생성 중..."
kubectl create namespace spring-cloud-msa || echo "네임스페이스가 이미 존재합니다."

# 7. Docker registry secret 생성 (ECR 액세스용)
echo "🔐 ECR 액세스를 위한 시크릿 생성 중..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
TOKEN=$(aws ecr get-login-password --region $REGION)

kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$TOKEN \
  --namespace=spring-cloud-msa || echo "시크릿이 이미 존재합니다."

echo "🎉 EKS 클러스터 생성이 완료되었습니다!"
echo ""
echo "다음 명령어로 클러스터 정보를 확인할 수 있습니다:"
echo "kubectl get nodes"
echo "kubectl get pods -A"
echo ""
echo "클러스터 삭제 시 다음 명령어를 사용하세요:"
echo "eksctl delete cluster --name $CLUSTER_NAME --region $REGION"