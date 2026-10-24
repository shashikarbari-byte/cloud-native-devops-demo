# Cloud-Native DevOps Demo (AWS + Azure)

A small Flask service used as the workload for an end-to-end DevOps setup:
containerised with Docker, packaged with Helm, deployed to **Kubernetes on AWS (EKS)
and Azure (AKS)** with **Terraform**, built and shipped through **GitHub Actions**,
and monitored with **Prometheus**.

## Architecture

```
 GitHub push/PR
      |
      v
 GitHub Actions ──> lint + tests ──> Helm lint ──> Docker build ──> Trivy scan ──> push image
      |
      └──> Terraform fmt / validate / config scan

 Terraform ──> AWS: VPC, ECR, EKS (managed nodes, IRSA)
           └─> Azure: VNet, ACR, AKS (autoscaling, workload identity, Log Analytics)

 Helm chart ──> Deployment (rolling update, probes, non-root, read-only FS)
            ├─> Service, HPA, PodDisruptionBudget
            └─> ServiceMonitor + PrometheusRule (optional)
```

## Repo layout

| Path | What it contains |
|------|------------------|
| `app/` | Flask service with `/healthz`, `/readyz`, `/metrics` and unit tests |
| `Dockerfile` | Multi-stage build, non-root user, gunicorn |
| `terraform/aws-eks/` | VPC, ECR repository, EKS cluster and managed node group |
| `terraform/azure-aks/` | VNet, ACR, AKS cluster, Log Analytics, AcrPull role assignment |
| `helm/devops-demo/` | Helm chart for the service |
| `.github/workflows/` | CI, Terraform checks, manual EKS deploy via OIDC |

## Run it locally

```bash
make install test      # install dev dependencies and run tests
make run               # build the image and run it on http://localhost:8080
curl localhost:8080/healthz
curl localhost:8080/metrics
```

## Provision infrastructure

> Creating an EKS or AKS cluster costs money. Run `terraform destroy` when you are done.

**AWS**
```bash
cd terraform/aws-eks
terraform init
terraform plan -out tfplan
terraform apply tfplan
$(terraform output -raw configure_kubectl)
```

**Azure**
```bash
az login
cd terraform/azure-aks
terraform init
terraform plan -out tfplan
terraform apply tfplan
$(terraform output -raw configure_kubectl)
```

For anything beyond a personal sandbox, enable the remote state backend that is
commented out in each `versions.tf`, and restrict
`cluster_endpoint_public_access_cidrs` to your own IP.

## Deploy with Helm

```bash
helm upgrade --install devops-demo helm/devops-demo \
  --namespace demo --create-namespace \
  --set image.repository=<registry>/devops-demo \
  --set image.tag=<tag>

kubectl -n demo port-forward svc/devops-demo 8080:80
```

To enable Prometheus scraping and alert rules (needs the Prometheus Operator, for
example `kube-prometheus-stack`):

```bash
helm upgrade --install devops-demo helm/devops-demo -n demo \
  --set monitoring.serviceMonitor.enabled=true \
  --set monitoring.prometheusRule.enabled=true
```

## CI/CD

- **CI** (`ci.yml`): ruff lint, pytest, `helm lint`, Docker build, Trivy image scan
  (fails on HIGH/CRITICAL), push to GHCR on `main`.
- **Terraform** (`terraform.yml`): `fmt -check`, `init`, `validate` for both stacks,
  plus a config security scan.
- **Deploy** (`deploy-eks.yml`): manual `workflow_dispatch` that assumes an AWS role
  through GitHub OIDC (no stored AWS keys) and runs `helm upgrade --install`.

## Design notes

- Containers run as non-root with a read-only root filesystem and all capabilities dropped.
- Rolling updates use `maxUnavailable: 0` so a deploy never reduces capacity.
- Readiness and liveness probes are separate endpoints.
- ECR tags are immutable and scanned on push; ACR admin user is disabled and
  the cluster pulls via the `AcrPull` role.
- IRSA (AWS) and workload identity (Azure) are enabled so pods can get cloud
  permissions without static credentials.

## Possible next steps

- Add an Ingress with the AWS Load Balancer Controller / NGINX and TLS via cert-manager.
- Move to GitOps with Argo CD or Flux.
- Add Grafana dashboards as ConfigMaps.
- Split Terraform into reusable modules with per-environment `tfvars`.
