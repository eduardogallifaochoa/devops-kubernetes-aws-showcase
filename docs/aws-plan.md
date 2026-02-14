# AWS Future Plan (Scaffold)

This document is a future implementation plan only. It uses placeholders and does not create AWS resources yet.

## 1) ECR Repository

Placeholders:
- `<AWS_REGION>`
- `<AWS_ACCOUNT_ID>`
- `<ECR_REPO_NAME>`

Run this:
```bash
aws ecr create-repository \
  --region <AWS_REGION> \
  --repository-name <ECR_REPO_NAME>

aws ecr get-login-password --region <AWS_REGION> | docker login \
  --username AWS \
  --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com

docker tag fastapi-showcase:local <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/<ECR_REPO_NAME>:latest
docker push <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/<ECR_REPO_NAME>:latest
```

Expected output:
- ECR repository exists.
- Docker login to ECR succeeds.
- Image is visible in ECR with the `latest` tag.

## 2) ECS Fargate + ALB Routing

Placeholders:
- `<ECS_CLUSTER_NAME>`
- `<ECS_SERVICE_DEV_NAME>`
- `<ECS_SERVICE_QA_NAME>`
- `<TASK_EXECUTION_ROLE_ARN>`
- `<TASK_ROLE_ARN>`
- `<ALB_NAME>`
- `<TARGET_GROUP_DEV_ARN>`
- `<TARGET_GROUP_QA_ARN>`

Plan:
- Create ECS cluster `<ECS_CLUSTER_NAME>`.
- Create task definition for FastAPI container exposing port `8000`.
- Create two ECS services (DEV and QA) on Fargate.
- Create ALB with listener rules routing `/dev*` and `/qa*` to separate target groups.
- Configure health checks on `/health`.

Run this:
```bash
# Placeholder sequence only; fill values before execution.
aws ecs create-cluster --cluster-name <ECS_CLUSTER_NAME>
# Register task definitions and create services for DEV/QA.
# Create ALB, listeners, and rules for /dev and /qa.
```

Expected output:
- ECS cluster and services running.
- ALB routes `/dev` and `/qa` correctly.
- Health checks on `/health` are passing.

## 3) CloudWatch Logs

Placeholders:
- `<CLOUDWATCH_LOG_GROUP_DEV>`
- `<CLOUDWATCH_LOG_GROUP_QA>`
- `<LOG_RETENTION_DAYS>`

Plan:
- Send ECS container stdout/stderr logs to CloudWatch Logs.
- Define retention and naming conventions per environment.

Run this:
```bash
aws logs create-log-group --log-group-name <CLOUDWATCH_LOG_GROUP_DEV> --region <AWS_REGION>
aws logs create-log-group --log-group-name <CLOUDWATCH_LOG_GROUP_QA> --region <AWS_REGION>
aws logs put-retention-policy --log-group-name <CLOUDWATCH_LOG_GROUP_DEV> --retention-in-days <LOG_RETENTION_DAYS> --region <AWS_REGION>
aws logs put-retention-policy --log-group-name <CLOUDWATCH_LOG_GROUP_QA> --retention-in-days <LOG_RETENTION_DAYS> --region <AWS_REGION>
```

Expected output:
- Log groups exist for DEV and QA.
- Retention policies are configured.

## 4) IAM Role Model

Placeholders:
- `<DEV_DEPLOY_ROLE_ARN>`
- `<QA_OPERATIONS_ROLE_ARN>`
- `<DEV_SERVICE_ARN>`
- `<QA_SERVICE_ARN>`

Policy goals:
- Dev role:
  - Can deploy/update only DEV ECS service.
  - Cannot update QA ECS service.
- QA role:
  - Can view CloudWatch logs for QA.
  - Can trigger `ecs:update-service --force-new-deployment` on QA service only.
  - Cannot change task definition image tags.

Run this:
```bash
# Create IAM roles and attach least-privilege policies scoped to specific ECS/Logs resources.
aws iam create-role --role-name <DEV_DEPLOY_ROLE_NAME> --assume-role-policy-document file://trust-policy.json
aws iam create-role --role-name <QA_OPERATIONS_ROLE_NAME> --assume-role-policy-document file://trust-policy.json
```

Expected output:
- IAM roles exist with scoped permissions for DEV deploy and QA operations.

## 5) Cost Avoidance Checklist

- Use small Fargate CPU/memory profiles for demo workloads.
- Keep minimum tasks at 1 only when needed; scale to 0 or delete when idle.
- Configure CloudWatch retention (`<LOG_RETENTION_DAYS>`) to limit storage costs.
- Avoid NAT Gateway for simple public-only demo paths when possible.
- Remove unused ECR images regularly.

## 6) Destroy Everything (AWS)

Run this (order matters):
```bash
# 1) Scale down and delete ECS services
aws ecs update-service --cluster <ECS_CLUSTER_NAME> --service <ECS_SERVICE_DEV_NAME> --desired-count 0
aws ecs update-service --cluster <ECS_CLUSTER_NAME> --service <ECS_SERVICE_QA_NAME> --desired-count 0
aws ecs delete-service --cluster <ECS_CLUSTER_NAME> --service <ECS_SERVICE_DEV_NAME> --force
aws ecs delete-service --cluster <ECS_CLUSTER_NAME> --service <ECS_SERVICE_QA_NAME> --force

# 2) Delete ALB and related resources
aws elbv2 delete-load-balancer --load-balancer-arn <ALB_ARN>
aws elbv2 delete-target-group --target-group-arn <TARGET_GROUP_DEV_ARN>
aws elbv2 delete-target-group --target-group-arn <TARGET_GROUP_QA_ARN>

# 3) Delete ECS cluster
aws ecs delete-cluster --cluster <ECS_CLUSTER_NAME>

# 4) Delete ECR images/repository
aws ecr batch-delete-image --repository-name <ECR_REPO_NAME> --image-ids imageTag=latest --region <AWS_REGION>
aws ecr delete-repository --repository-name <ECR_REPO_NAME> --force --region <AWS_REGION>

# 5) Delete CloudWatch logs
aws logs delete-log-group --log-group-name <CLOUDWATCH_LOG_GROUP_DEV> --region <AWS_REGION>
aws logs delete-log-group --log-group-name <CLOUDWATCH_LOG_GROUP_QA> --region <AWS_REGION>

# 6) Delete IAM roles and policies created for this demo
aws iam delete-role --role-name <DEV_DEPLOY_ROLE_NAME>
aws iam delete-role --role-name <QA_OPERATIONS_ROLE_NAME>
```

Expected output:
- ECS, ALB, ECR, CloudWatch, and IAM demo resources are removed.
- Ongoing AWS charges are minimized.
