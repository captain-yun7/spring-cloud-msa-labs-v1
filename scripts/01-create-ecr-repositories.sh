#!/bin/bash

# ECR 리포지토리 생성 스크립트
# Usage: ./01-create-ecr-repositories.sh [region]

set -e

# 기본 설정
REGION=${1:-ap-northeast-2}
REPOSITORY_PREFIX="spring-cloud-msa"

# 서비스 목록
services=(
    "api-gateway"
    "config-server"
    "eureka-server"
    "user-service"
    "product-service"
    "order-service"
    "payment-service"
    "notification-service"
)

echo "🚀 ECR 리포지토리 생성 시작"
echo "Region: $REGION"
echo "Repository Prefix: $REPOSITORY_PREFIX"
echo "Services: ${services[*]}"
echo ""

# AWS CLI 설치 확인
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI가 설치되어 있지 않습니다."
    exit 1
fi

# AWS 자격증명 확인
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS 자격증명이 설정되어 있지 않습니다."
    echo "aws configure를 실행하여 설정하세요."
    exit 1
fi

# 각 서비스별 ECR 리포지토리 생성
for service in "${services[@]}"; do
    repository_name="$REPOSITORY_PREFIX/$service"
    
    echo "📦 Creating repository: $repository_name"
    
    # 리포지토리가 이미 존재하는지 확인
    if aws ecr describe-repositories --repository-names "$repository_name" --region "$REGION" &> /dev/null; then
        echo "   ⚠️  Repository already exists: $repository_name"
    else
        # 리포지토리 생성
        aws ecr create-repository \
            --repository-name "$repository_name" \
            --region "$REGION" \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256 > /dev/null
        
        echo "   ✅ Successfully created: $repository_name"
        
        # 라이프사이클 정책 설정 (이미지 10개까지 보관)
        aws ecr put-lifecycle-policy \
            --repository-name "$repository_name" \
            --region "$REGION" \
            --lifecycle-policy-text '{
                "rules": [
                    {
                        "rulePriority": 1,
                        "description": "Keep last 10 images",
                        "selection": {
                            "tagStatus": "any",
                            "countType": "imageCountMoreThan",
                            "countNumber": 10
                        },
                        "action": {
                            "type": "expire"
                        }
                    }
                ]
            }' > /dev/null
        
        echo "   📋 Lifecycle policy applied"
    fi
done

echo ""
echo "🎉 ECR 리포지토리 생성 완료!"

# 생성된 리포지토리 목록 출력
echo ""
echo "📋 생성된 리포지토리 목록:"
for service in "${services[@]}"; do
    repository_name="$REPOSITORY_PREFIX/$service"
    repository_uri=$(aws ecr describe-repositories --repository-names "$repository_name" --region "$REGION" --query 'repositories[0].repositoryUri' --output text)
    echo "   $service: $repository_uri"
done

echo ""
echo "💡 다음 단계: ./02-build-and-push-images.sh 실행"