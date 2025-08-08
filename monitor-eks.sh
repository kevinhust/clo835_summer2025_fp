#\!/bin/bash
echo "🔍 EKS集群创建监控脚本"
echo "========================"
echo ""

while true; do
    echo "⏰ $(date '+%Y-%m-%d %H:%M:%S')"
    
    # 检查集群状态
    STATUS=$(aws eks describe-cluster --region us-east-1 --name clo835-eks-cluster --query "cluster.status" --output text 2>/dev/null)
    
    if [ "$STATUS" = "ACTIVE" ]; then
        echo "✅ EKS集群创建完成！状态: $STATUS"
        
        # 检查节点组
        echo "🔍 检查节点组状态..."
        NODE_STATUS=$(aws eks describe-nodegroup --region us-east-1 --cluster-name clo835-eks-cluster --nodegroup-name clo835-eks-nodes --query "nodegroup.status" --output text 2>/dev/null)
        echo "📋 节点组状态: $NODE_STATUS"
        
        # 获取集群信息
        echo ""
        echo "📊 集群详细信息:"
        aws eks describe-cluster --region us-east-1 --name clo835-eks-cluster --query "cluster.{Status:status,Version:version,Endpoint:endpoint,CreatedAt:createdAt}" --output table
        
        echo ""
        echo "🎉 可以执行以下命令更新kubeconfig:"
        echo "aws eks update-kubeconfig --region us-east-1 --name clo835-eks-cluster"
        break
        
    elif [ "$STATUS" = "FAILED" ]; then
        echo "❌ EKS集群创建失败！状态: $STATUS"
        break
        
    else
        echo "⏳ EKS集群状态: $STATUS (还在创建中...)"
        echo "   预计还需要几分钟完成..."
    fi
    
    echo ""
    echo "---"
    sleep 60
done
