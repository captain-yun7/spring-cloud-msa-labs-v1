#!/bin/bash

# Docker 이미지 빌드 및 ECR 푸시 스크립트
# Usage: ./02-build-and-push-images.sh [region] [tag]

set -e

# 기본 설정
REGION=${1:-ap-northeast-2}
TAG=${2:-latest}
REPOSITORY_PREFIX="spring-cloud-msa"

# AWS 계정 ID 가져오기
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# 서비스 목록
services=(
    "api-gateway"
    "eureka-server"
    "user-service"
    "product-service"
    "order-service"
    "payment-service"
    "notification-service"
)

echo "🚀 Docker 이미지 빌드 및 푸시 시작"
echo "Region: $REGION"
echo "Account ID: $ACCOUNT_ID"
echo "ECR Registry: $ECR_REGISTRY"
echo "Tag: $TAG"
echo "Services: ${services[*]}"
echo ""

# 루트 디렉토리 확인
if [[ ! -d "backend" ]]; then
    echo "❌ backend 디렉토리가 없습니다. 프로젝트 루트에서 실행하세요."
    exit 1
fi

# AWS CLI 설치 확인
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI가 설치되어 있지 않습니다."
    exit 1
fi

# Docker 설치 확인
if ! command -v docker &> /dev/null; then
    echo "❌ Docker가 설치되어 있지 않습니다."
    exit 1
fi

# ECR 로그인
echo "🔐 ECR 로그인 중..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"
echo "✅ ECR 로그인 완료"
echo ""

# 병렬 빌드를 위한 함수 정의
build_and_push_service() {
    local service=$1
    local service_dir="backend/$service"
    local image_name="$ECR_REGISTRY/$REPOSITORY_PREFIX/$service:$TAG"
    
    echo "🔨 처리 중: $service"
    
    if [[ ! -d "$service_dir" ]]; then
        echo "   ⚠️  디렉토리가 없습니다: $service_dir"
        return 1
    fi
    
    # 서비스 디렉토리로 이동
    cd "$service_dir"
    
    # Gradlew 실행 권한 확인
    if [[ -f "./gradlew" ]] && [[ ! -x "./gradlew" ]]; then
        chmod +x ./gradlew
    fi
    
    # 이미지 빌드
    echo "   📦 Building image: $image_name"
    if ./gradlew bootBuildImage --imageName="$image_name" > "/tmp/${service}_build.log" 2>&1; then
        echo "   ✅ Build successful: $service"
        
        # 이미지 푸시
        echo "   📤 Pushing image to ECR: $service"
        if docker push "$image_name" > "/tmp/${service}_push.log" 2>&1; then
            echo "   ✅ Push successful: $service"
        else
            echo "   ❌ Push failed: $service"
            cat "/tmp/${service}_push.log"
        fi
    else
        echo "   ❌ Build failed: $service"
        cat "/tmp/${service}_build.log"
    fi
    
    # 루트 디렉토리로 복귀
    cd - > /dev/null
}

# 병렬 처리로 각 서비스 빌드 및 푸시
echo "🚀 병렬로 모든 서비스 빌드 시작..."
pids=()

for service in "${services[@]}"; do
    build_and_push_service "$service" &
    pids+=($!)
done

# 모든 백그라운드 작업 완료 대기
echo "⏳ 모든 빌드 작업 완료 대기 중..."
for pid in "${pids[@]}"; do
    wait "$pid"
done

echo "🎉 모든 이미지 빌드 및 푸시 완료!"
echo ""

# 푸시된 이미지 목록 확인
echo "📋 ECR에 푸시된 이미지 목록:"
for service in "${services[@]}"; do
    repository_name="$REPOSITORY_PREFIX/$service"
    
    # 최신 이미지 정보 가져오기
    if aws ecr describe-images --repository-name "$repository_name" --region "$REGION" --image-ids imageTag="$TAG" &> /dev/null; then
        image_digest=$(aws ecr describe-images --repository-name "$repository_name" --region "$REGION" --image-ids imageTag="$TAG" --query 'imageDetails[0].imageDigest' --output text)
        image_size=$(aws ecr describe-images --repository-name "$repository_name" --region "$REGION" --image-ids imageTag="$TAG" --query 'imageDetails[0].imageSizeInBytes' --output text)
        size_mb=$((image_size / 1024 / 1024))
        
        echo "   ✅ $service: $ECR_REGISTRY/$repository_name:$TAG (${size_mb}MB)"
    else
        echo "   ❌ $service: 이미지를 찾을 수 없습니다"
    fi
done

echo ""
echo "💡 다음 단계:"
echo "   1. Kubernetes 매니페스트 파일에서 이미지 URL 업데이트"
echo "   2. kubectl apply -f k8s/ 로 배포 시작"