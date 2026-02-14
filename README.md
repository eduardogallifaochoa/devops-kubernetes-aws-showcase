# FastAPI DevOps Jarvis Project

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?logo=ubuntu&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-29.2.1-2496ED?logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-326CE5?logo=kubernetes&logoColor=white)

Simple but production-like portfolio repository with FastAPI, Docker Compose (DEV/QA), kind Kubernetes with Ingress, GitHub Actions + GHCR, and an AWS future deployment plan.

## Project Structure

```text
app/
tests/
k8s/
.github/workflows/
scripts/
docs/
README.md
Makefile
Dockerfile
docker-compose.yml
pyproject.toml
requirements.txt
requirements-dev.txt
```

## Prerequisites

- Python 3.12
- Docker + Docker Compose plugin
- kind
- kubectl
- make
- GitHub repository with Actions enabled

## Install kind and kubectl (Ubuntu VM)

### Run this

```bash
make install-k8s-tools
kubectl version --client
kind --version
```

### Expected output

- `kubectl` client version is printed.
- `kind` version is printed.
- Phase 2 commands become available in your VM.

## One-Command Teardown (Local)

### Run this

```bash
KIND_CLUSTER_NAME=<KIND_CLUSTER_NAME> make destroy-all
```

### Expected output

- Docker Compose services are stopped and removed.
- kind cluster is deleted if `kind` and `kubectl` are installed.
- Unused local Docker images and volumes are pruned.
- GHCR and AWS resources are left untouched (manual cleanup still required).

## Phase 1: Local (Docker Compose DEV/QA)

### Run this

```bash
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
make up
curl -s http://localhost:8000/health
curl -s http://localhost:8001/version
make test
make lint
```

### Expected output

- `http://localhost:8000/health` returns JSON with `status=ok`, `env=dev`, `version=0.1.0-dev`.
- `http://localhost:8001/version` returns JSON with `env=qa`, `version=0.1.0-qa`.
- `make test` passes.
- `make lint` passes.

### Observability (Logs + Health + Troubleshooting)

#### Read logs

Run this:
```bash
make logs
```

Expected output:
- Request log lines include `env=<value> version=<value> method=<value> path=<value> status=<value> duration_ms=<value>`.

#### Check container health

Run this:
```bash
docker compose ps
```

Expected output:
- `api-dev` and `api-qa` show `healthy` state.

#### Typical issues

- Port conflict on `8000` or `8001`:
  - Stop the process using that port or change port mapping in `docker-compose.yml`.
- Containers restart repeatedly:
  - Check `make logs` and confirm `/health` responds.
- Local Python tooling fails:
  - Recreate `.venv` and reinstall `requirements-dev.txt`.
- `.venv/bin/activate` does not exist:
  - Install venv support and recreate the environment.
  - Run `sudo apt update && sudo apt install -y python3.12-venv python3-pip`.
  - Run `rm -rf .venv && python3.12 -m venv .venv && source .venv/bin/activate`.

### Destroy everything (local)

Run this:
```bash
make down
docker image prune -f
docker volume prune -f
```

Expected output:
- Compose services and volumes are removed.
- Unused images and volumes are pruned.

## Phase 2: Kubernetes local with kind

### Run this

```bash
KIND_CLUSTER_NAME=<KIND_CLUSTER_NAME> make k8s-up
kubectl get pods -n showcase
kubectl get ingress -n showcase
curl -s http://localhost/dev/health
curl -s http://localhost/qa/version
```

### Expected output

- DEV and QA pods are `Running` and ready in namespace `showcase`.
- Ingress exists and routes from localhost.
- `http://localhost/dev/health` returns `env=dev`.
- `http://localhost/qa/version` returns `env=qa`.

### Observability and troubleshooting

#### Kubernetes logs

Run this:
```bash
kubectl logs -n showcase -l app=fastapi-showcase --all-containers=true --tail=100
```

Expected output:
- Request logs for DEV/QA with env/version fields.

#### Common failures

- Ingress not ready:
  - Check controller: `kubectl get pods -n ingress-nginx`.
- Pods not ready:
  - Check events: `kubectl describe pod -n showcase <POD_NAME>`.
- Wrong route behavior:
  - Verify rewrite annotations in `k8s/ingress.yaml`.

### Destroy everything (k8s)

Run this:
```bash
KIND_CLUSTER_NAME=<KIND_CLUSTER_NAME> make k8s-down
```

Expected output:
- Ingress controller resources and showcase workloads are removed.
- kind cluster is deleted.

## Phase 3: GitHub Actions + GHCR

### Required repository settings

- Actions enabled in the repository.
- Workflow permissions allow package write.
- Package visibility configured in GitHub Packages as needed.

### Run this

```bash
git add .
git commit -m "Initial DevOps showcase stack"
git push origin <BRANCH_NAME>
```

### Expected output

- `push` and `pull_request` run lint/test/build.
- `push` also logs in to GHCR and pushes:
  - `ghcr.io/<GH_USERNAME>/<REPO_NAME>:latest`
  - `ghcr.io/<GH_USERNAME>/<REPO_NAME>:sha-<GIT_SHA>`

### Verify image in GHCR

Run this:
```bash
# Open GitHub UI: <GH_REPO_URL>/pkgs/container/<REPO_NAME>
```

Expected output:
- GHCR package exists with `latest` and `sha-*` tags.

### No secrets committed guidance

- Use `GITHUB_TOKEN` in workflow for GHCR login.
- Never commit AWS credentials, private keys, `.env`, or access tokens.
- Keep placeholders explicit in docs: `<AWS_REGION>`, `<AWS_ACCOUNT_ID>`, `<GH_USERNAME>`, etc.

### Destroy everything (CI/GHCR)

Run this:
```bash
# Remove package tags or package in GitHub Packages UI
# Optionally disable workflow in Actions UI or remove .github/workflows/ci.yml
```

Expected output:
- No new workflow runs after disable/removal.
- No retained GHCR images after deletion.

## Phase 3.5: CD with GitHub Environments (DEV/QA)

Workflow file: `.github/workflows/cd.yml`

Behavior:
- Push to `main` deploys to `dev` environment automatically (smoke test with GHCR image).
- Manual run (`workflow_dispatch`) can deploy to `qa` with a selected image tag.
- `qa` deployment is intended to be protected by GitHub Environment approvals.

### Configure environments in GitHub

1. Go to repository settings -> Environments.
2. Create environment `dev` (no required reviewers).
3. Create environment `qa` and set required reviewers (QA leads/team).

### Run this

```bash
# Automatic DEV deployment
git push origin main

# Manual QA deployment
# GitHub UI -> Actions -> cd -> Run workflow
# target_environment=qa
# image_tag=sha-<GIT_SHA> or latest
```

### Expected output

- `cd` workflow runs.
- `deploy-dev` job runs automatically on pushes to `main`.
- `deploy-qa` waits for QA environment approval (if configured) and then runs.
- Health smoke test calls `/health` successfully for the selected image.

### Destroy everything (CD runtime)

Run this:
```bash
# No persistent infra is created by cd.yml.
# It starts temporary smoke-test containers in the GitHub runner and removes them in the same job.
# Optional cleanup: disable workflow if you want zero future runs.
```

Expected output:
- No long-lived runtime resources remain from CD runs.

## Phase 4: AWS Future Scaffold (docs only)

Detailed future plan is in `docs/aws-plan.md`.

### Run this

```bash
cat docs/aws-plan.md
```

### Expected output

- A placeholder-based AWS roadmap using:
  - `<AWS_REGION>`
  - `<AWS_ACCOUNT_ID>`
  - `<ECR_REPO_NAME>`
  - `<ECS_CLUSTER_NAME>`
  - `<ALB_NAME>`
  - IAM role placeholders for DEV/QA scope.

### Destroy everything (AWS)

Run this:
```bash
# Follow the ordered destroy commands in docs/aws-plan.md
```

Expected output:
- Planned sequence removes ECS, ALB, ECR, CloudWatch, and IAM demo resources to avoid costs.

## Human Guide

For a simple human-language explanation with metaphors and business value:

- `docs/bitacora.md`
