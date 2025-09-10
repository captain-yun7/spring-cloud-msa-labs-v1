#!/bin/bash

# 모든 Spring Cloud 서비스의 리소스를 t3.medium 환경에 맞게 최적화

services=(
    "user-service"
    "product-service"
    "order-service"
    "payment-service"
    "notification-service"
    "api-gateway"
    "eureka-server"
)

echo "🔧 리소스 최적화 시작..."

for service in "${services[@]}"; do
    echo "📝 $service 리소스 최적화 중..."
    
    # 각 서비스의 리소스 요청/제한 수정
    kubectl patch deployment $service -n spring-cloud-msa --type='merge' -p='{
        "spec": {
            "template": {
                "spec": {
                    "containers": [{
                        "name": "'$service'",
                        "resources": {
                            "requests": {
                                "memory": "256Mi",
                                "cpu": "100m"
                            },
                            "limits": {
                                "memory": "512Mi", 
                                "cpu": "300m"
                            }
                        }
                    }]
                }
            }
        }
    }' || echo "⚠️  $service 패치 실패"
done

echo "✅ 리소스 최적화 완료!"
echo ""
echo "📊 업데이트된 리소스 현황:"
kubectl get pods -n spring-cloud-msa -o custom-columns="NAME:.metadata.name,CPU-REQ:.spec.containers[0].resources.requests.cpu,CPU-LIM:.spec.containers[0].resources.limits.cpu,MEM-REQ:.spec.containers[0].resources.requests.memory,MEM-LIM:.spec.containers[0].resources.limits.memory"