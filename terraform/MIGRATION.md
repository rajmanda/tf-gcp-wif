# Migration from Kubernetes to Cloud Run

This document explains the migration of the Kalyanam Angular application from GKE (Google Kubernetes Engine) to Cloud Run.

## Overview

### Before: Kubernetes Deployment

**Resources:**
- Deployment (1 replica, scaling to 2)
- Service (ClusterIP, port 80)
- HorizontalPodAutoscaler (memory-based, 70% threshold)
- Service Account (gke-secret-accessor)
- Nginx Ingress Controller
- Static external IP

**Complexity:**
- Multiple YAML files
- Cluster management required
- Manual scaling configuration
- Ingress controller setup
- Namespace management

### After: Cloud Run Deployment

**Resources:**
- Cloud Run Service (auto-scaling 0-N)
- Service Account (minimal permissions)
- Public HTTPS endpoint (automatic)

**Benefits:**
- Single Terraform resource
- Fully managed (no cluster)
- Automatic scaling (including to zero)
- Built-in HTTPS with managed certificates
- Simplified configuration

## Key Changes

### 1. Auto-scaling

**Kubernetes:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: kalyanam-hpa
spec:
  minReplicas: 1
  maxReplicas: 2
  metrics:
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 70
```

**Cloud Run:**
- Automatic based on request concurrency
- Scales from 0 to 100 instances (configurable)
- No manual configuration needed
- Scales to zero when idle (cost savings)

### 2. Networking

**Kubernetes:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
    - host: kalyanam.com
      http:
        paths:
          - path: /
            backend:
              service:
                name: kalyanam
                port:
                  number: 80
```

**Cloud Run:**
- Automatic HTTPS endpoint: `https://kalyanam-frontend-xxx.a.run.app`
- Managed TLS certificates
- Domain mapping available: `gcloud run domain-mappings create`
- No ingress controller needed

### 3. Service Account

**Kubernetes:**
```yaml
serviceAccountName: gke-secret-accessor
```

**Cloud Run:**
```hcl
resource "google_service_account" "kalyanam_frontend_sa" {
  account_id   = "kalyanam-frontend-sa"
  display_name = "Service Account for Kalyanam Frontend"
}
```

### 4. Deployment Process

**Kubernetes:**
```bash
# Build image
docker build -t dockerrajmanda/kalyanam:405 .
docker push dockerrajmanda/kalyanam:405

# Deploy
kubectl apply -f kalyanam-deployment.yaml
kubectl apply -f kalyanam-service.yaml
kubectl apply -f kalyanam-hpa.yaml
kubectl apply -f kalyanam-ingress.yaml

# Check status
kubectl get pods -n kalyanam
kubectl get services -n kalyanam
kubectl describe ingress kalyanam -n kalyanam
```

**Cloud Run:**
```bash
# Build image (same)
docker build -t dockerrajmanda/kalyanam:405 .
docker push dockerrajmanda/kalyanam:405

# Deploy with Terraform
terraform apply

# Check status
gcloud run services describe kalyanam-frontend --region=us-central1
```

## Cost Comparison

### Kubernetes (GKE)

**Fixed Costs:**
- Cluster management: ~$74/month (per cluster)
- Node pool: ~$25-50/month per node (e2-medium)
- Static IP: ~$7/month
- Load balancer: ~$18/month

**Total Minimum:** ~$124-149/month (even with zero traffic)

### Cloud Run

**Variable Costs:**
- Only pay for actual usage
- Scales to zero when idle
- Free tier: 2M requests/month

**Examples:**
- Zero traffic: $0/month
- 10K requests/month: $0/month (free tier)
- 500K requests/month: ~$2-3/month
- 5M requests/month: ~$12-18/month

**Savings:** 90%+ for low to medium traffic applications

## Feature Comparison

| Feature | Kubernetes (GKE) | Cloud Run |
|---------|------------------|------------|
| Cluster Management | Manual | Fully Managed |
| Scaling | HPA (manual config) | Automatic |
| Scale to Zero | No | Yes |
| HTTPS/TLS | Manual (Ingress) | Automatic |
| Load Balancing | Manual setup | Automatic |
| Cold Starts | No | Yes (minimal for this app) |
| Debugging | Full pod access | Logs only |
| Networking | Full control | Simplified |
| Cost Model | Pay for nodes | Pay per use |
| Deployment | kubectl apply | Single command |
| Health Checks | Manual config | Automatic |
| Rollback | Manual | Automatic (revisions) |

## Docker Image Compatibility

**Good news:** The existing Dockerfile works with Cloud Run with no changes!

### Why it works:

1. **Multi-stage build** is supported
2. **Port 80** is acceptable (Cloud Run can handle any port)
3. **NGINX** works perfectly on Cloud Run
4. **No persistent state** required
5. **Stateless** application

### What Cloud Run provides automatically:

1. **PORT environment variable** (not needed for this app, NGINX uses 80)
2. **Request timeout** (up to 60 minutes)
3. **Concurrency** (80 requests per instance default)
4. **Health checks** (automatic based on HTTP responses)

## Migration Steps (Already Done)

1. ✅ **Analyze K8s deployment** - Reviewed kalyanam-deployment.yaml
2. ✅ **Create Terraform files** - All .tf files created
3. ✅ **Configure variables** - terraform.tfvars ready
4. ✅ **Set up service account** - Minimal permissions
5. ✅ **Configure health checks** - HTTP checks on /
6. ✅ **Enable public access** - allUsers IAM binding
7. ✅ **Create documentation** - README, QUICK_START

## What You Need to Do

1. **Review the configuration:**
   ```bash
   cd terraform
   cat terraform.tfvars
   cat 005-deploy-cloud-run.tf
   ```

2. **Deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Test:**
   ```bash
   SERVICE_URL=$(terraform output -raw service_url)
   curl -I $SERVICE_URL
   open $SERVICE_URL
   ```

4. **Decommission K8s (optional):**
   ```bash
   kubectl delete -f kalyanam-deployment.yaml
   # Keep cluster if other apps are running
   ```

## Rollback Plan

If you need to rollback to Kubernetes:

1. **Keep the Kubernetes YAML files** (already in repo)
2. **Keep the Docker image** (on Docker Hub)
3. **Redeploy to K8s:**
   ```bash
   kubectl apply -f kalyanam-deployment.yaml
   ```

## Monitoring and Observability

### Kubernetes
- kubectl logs
- kubectl describe
- Kubernetes Dashboard
- Prometheus/Grafana (if installed)

### Cloud Run
- Cloud Logging (automatic)
- Cloud Monitoring (automatic)
- Cloud Trace (automatic)
- Built-in metrics dashboard

**Command:**
```bash
# View logs
gcloud run services logs read kalyanam-frontend --region=us-central1

# Live logs
gcloud run services logs tail kalyanam-frontend --region=us-central1

# Metrics (in console)
gcloud run services describe kalyanam-frontend --region=us-central1
```

## Frequently Asked Questions

### Q: Will my application work without changes?
**A:** Yes! Your existing Docker image works as-is.

### Q: What about the gke-secret-accessor service account?
**A:** Not needed. Cloud Run uses a new service account with minimal permissions.

### Q: Can I scale as much as I need?
**A:** Yes! Cloud Run can scale to 100 instances by default (configurable to 1000).

### Q: What about cold starts?
**A:** For a static Angular app served by NGINX, cold starts are minimal (~1-2 seconds).

### Q: Can I keep my custom domain?
**A:** Yes! Use Cloud Run domain mapping:
```bash
gcloud run domain-mappings create --service=kalyanam-frontend --domain=www.kalyanam.com
```

### Q: What if I need to go back to Kubernetes?
**A:** Keep your K8s YAML files and simply redeploy. The Docker image hasn't changed.

### Q: How do I update to a new version?
**A:** Update `image_uri` in `terraform.tfvars` and run `terraform apply`. Cloud Run does rolling updates automatically.

### Q: Can I limit costs?
**A:** Yes! Set max instances in `005-deploy-cloud-run.tf`:
```hcl
scaling {
  max_instance_count = 10
}
```

## Conclusion

Cloud Run is ideal for the Kalyanam frontend because:

1. ✅ **Stateless** Angular SPA
2. ✅ **Variable traffic** (weddings are event-based)
3. ✅ **Cost-sensitive** (pay only for actual usage)
4. ✅ **Low maintenance** (fully managed)
5. ✅ **Fast deployment** (single command)

The migration reduces complexity, costs, and operational overhead while maintaining the same functionality.
