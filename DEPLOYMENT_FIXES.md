# CLO835 Final Project - 部署问题修复总结

## 问题发现和解决方案

在部署过程中发现了多个问题，以下是详细的问题分析和解决方案。

### 1. M1 Mac架构兼容性问题

**问题描述:**
- M1 Mac构建的Docker镜像是ARM64架构
- EKS节点是AMD64架构，导致镜像无法运行

**解决方案:**
- 修改`.github/workflows/ci-cd.yml`添加多架构构建支持
- 添加`docker/setup-buildx-action@v3`
- 设置`platforms: linux/amd64,linux/arm64`

**修复文件:**
```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
  
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    platforms: linux/amd64,linux/arm64
```

### 2. EBS CSI Driver未配置

**问题描述:**
- 新的EKS集群默认不包含EBS CSI driver
- PVC无法创建，MySQL pod无法启动

**解决方案:**
- 在Terraform中添加OIDC provider配置
- 添加EBS CSI driver IAM角色
- 添加EBS CSI driver addon

**修复文件: `terraform/main.tf`**
```hcl
# OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.clo835_eks.identity[0].oidc[0].issuer
}

# EBS CSI Driver Addon
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.clo835_eks.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn
}
```

### 3. S3访问权限问题

**问题描述:**
- Webapp无法访问S3存储桶中的背景图片
- IAM角色配置不正确

**解决方案:**
- 在Terraform中添加应用程序IAM角色（LabRole）
- 配置S3访问策略
- 在K8s service account中添加IAM角色注解

**修复文件: `terraform/main.tf`**
```hcl
# Application S3 Access IAM Role
resource "aws_iam_role" "app_s3_role" {
  name = "LabRole"
  assume_role_policy = jsonencode({
    # OIDC provider configuration
  })
}

# S3 Access Policy
resource "aws_iam_policy" "s3_background_images_access" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [
        aws_s3_bucket.clo835_background_images.arn,
        "${aws_s3_bucket.clo835_background_images.arn}/*"
      ]
    }]
  })
}
```

### 4. Docker容器权限问题

**问题描述:**
- 非root用户无法绑定到端口81（特权端口）
- Flask应用启动失败

**解决方案:**
- 修改Dockerfile使用root用户
- 保持端口81符合项目要求

**修复文件: `Dockerfile`**
```dockerfile
# Use root user to bind to port 81 (privileged port)
# USER appuser (commented out)
```

### 5. K8s Manifests配置问题

**问题描述:**
- Webapp deployment使用占位符镜像URI
- Service account缺少IAM角色注解

**解决方案:**
- 使用环境变量占位符
- 在CI/CD中动态替换
- 添加IAM角色注解

**修复文件:**
- `k8s-manifests/webapp-deployment.yaml`: 使用`${ECR_REPOSITORY_URI}`
- `k8s-manifests/rbac.yaml`: 添加`eks.amazonaws.com/role-arn`注解

### 6. CI/CD流程优化

**问题描述:**
- 部署流程需要手动干预
- 缺少自动化配置更新

**解决方案:**
- 修改GitHub Actions workflow
- 添加manifest更新步骤
- 自动化部署流程

**修复文件: `.github/workflows/ci-cd.yml`**
```yaml
- name: Update deployment manifests and deploy
  run: |
    # Update manifests with current values
    sed -i "s|\${ECR_REPOSITORY_URI}|${ECR_URL}|g" k8s-manifests/webapp-deployment.yaml
    sed -i "s|\${IAM_ROLE_ARN}|${IAM_ROLE_ARN}|g" k8s-manifests/rbac.yaml
    
    # Apply manifests
    kubectl apply -f k8s-manifests/
```

## 最佳实践和建议

### 1. 架构兼容性
- 始终使用多架构Docker构建
- 在CI/CD中指定目标平台

### 2. 基础设施即代码
- 在Terraform中包含所有必需的附加组件
- 使用OIDC provider而不是长期访问密钥

### 3. 权限管理
- 使用IAM角色而不是访问密钥
- 遵循最小权限原则

### 4. 部署自动化
- 使用环境变量和占位符
- 在CI/CD中动态更新配置

### 5. 监控和验证
- 添加健康检查
- 验证部署状态

## 部署脚本使用

创建了自动化部署脚本`deploy.sh`：

```bash
# 完整部署
./deploy.sh all

# 仅部署基础设施
./deploy.sh infra

# 仅部署应用
./deploy.sh app

# 验证部署状态
./deploy.sh verify
```

## 测试验证

部署完成后，应用程序应该：

1. ✅ MySQL pod正常运行 (1/1 Ready)
2. ✅ Webapp pod正常运行 (1/1 Ready)
3. ✅ S3背景图片下载成功
4. ✅ LoadBalancer提供外部访问
5. ✅ 应用程序响应HTTP请求

## 故障排除

如果遇到问题：

1. **检查pod状态**: `kubectl get pods -n fp`
2. **查看pod日志**: `kubectl logs <pod-name> -n fp`
3. **检查服务endpoints**: `kubectl get endpoints -n fp`
4. **验证IAM角色**: 检查service account注解
5. **检查EBS CSI**: 确保driver正常运行

## 项目合规性

所有修复都严格遵守CLO835fp.md文档要求：

- ✅ Flask应用监听端口81
- ✅ 使用ConfigMap提供配置
- ✅ 使用Secrets提供敏感数据
- ✅ 支持S3背景图片
- ✅ MySQL数据持久化
- ✅ LoadBalancer外部访问

这些修复确保了未来的部署可以顺利完成，无需手动干预。
