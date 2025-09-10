#!/bin/bash

# EKS 클러스터 생성 전 필수 도구 확인 스크립트

set -e

echo "🔍 EKS 클러스터 생성을 위한 필수 도구 확인 중..."

# 필수 도구 리스트
REQUIRED_TOOLS=("aws" "eksctl" "kubectl")
MISSING_TOOLS=()

# 각 도구 확인
for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v $tool &> /dev/null; then
        echo "✅ $tool: 설치됨"
        case $tool in
            "aws")
                echo "   버전: $(aws --version | head -n1)"
                ;;
            "eksctl")
                echo "   버전: $(eksctl version)"
                ;;
            "kubectl")
                echo "   버전: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
                ;;
        esac
    else
        echo "❌ $tool: 설치되지 않음"
        MISSING_TOOLS+=($tool)
    fi
done

# AWS 자격증명 확인
echo ""
echo "🔐 AWS 자격증명 확인 중..."
if aws sts get-caller-identity &> /dev/null; then
    echo "✅ AWS 자격증명 설정됨"
    aws sts get-caller-identity --output table
else
    echo "❌ AWS 자격증명이 설정되지 않았습니다."
    echo "   다음 명령어로 설정하세요: aws configure"
    MISSING_TOOLS+=("aws-credentials")
fi


# 결과 출력
echo ""
if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
    echo "🎉 모든 필수 도구가 설치되어 있습니다! EKS 클러스터 생성을 진행할 수 있습니다."
    echo ""
    echo "다음 명령어로 클러스터를 생성하세요:"
    echo "./scripts/03-create-eks-cluster.sh"
else
    echo "⚠️  다음 도구들이 누락되어 있습니다:"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "   - $tool"
    done
    echo ""
    echo "설치 가이드:"
    echo "🔧 AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
    echo "🔧 eksctl: https://eksctl.io/installation/"
    echo "🔧 kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi