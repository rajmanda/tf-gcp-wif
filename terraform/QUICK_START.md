# Quick Start Guide - Kalyanam Frontend on Cloud Run

Get your Kalyanam Angular application running on Google Cloud Run in 5 minutes!

## Prerequisites Checklist

- [ ] GCP account with billing enabled
- [ ] Project ID: `properties-app-418208` (or your project)
- [ ] Terraform installed (>= 1.0)
- [ ] `gcloud` CLI installed and authenticated

## 5-Minute Deployment

### Step 1: Authenticate with GCP (30 seconds)

```bash
# Login to GCP
gcloud auth login

# Set your project
gcloud config set project properties-app-418208

# Verify authentication
gcloud auth application-default login
```

### Step 2: Clone and Navigate (30 seconds)

```bash
# Clone the repository
git clone https://github.com/rajmanda/tf-gcp-wif.git
cd tf-gcp-wif

# Checkout the frontend deployment branch
git checkout feature/deploy-kalyanam-as-cloudrun

# Navigate to terraform directory
cd terraform
```

### Step 3: Configure (Optional) (30 seconds)

Review and customize `terraform.tfvars` if needed:

```bash
cat terraform.tfvars
```

**Default Configuration:**
- Project: `properties-app-418208`
- Region: `us-central1`
- Service: `kalyanam-frontend`
- Image: `docker.io/dockerrajmanda/kalyanam:405`

To use a different Docker image tag:
```bash
# Edit terraform.tfvars
nano terraform.tfvars

# Change image_uri to:
image_uri = "docker.io/dockerrajmanda/kalyanam:YOUR_TAG"
```

### Step 4: Deploy (3 minutes)

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy!
terraform apply
```

When prompted, type `yes` and press Enter.

### Step 5: Access Your App (30 seconds)

```bash
# Get the service URL
terraform output service_url

# Open in browser
open $(terraform output -raw service_url)

# Or using curl
curl -I $(terraform output -raw service_url)
```

**Done!** Your Kalyanam frontend is now live on Cloud Run! 🎉

## What Was Created?

```
✓ Cloud Run service (kalyanam-frontend)
✓ Service Account (kalyanam-frontend-sa)
✓ IAM policies (public access)
✓ API enablements (Cloud Run, IAM)
```

## Common Commands

### View Service Details
```bash
gcloud run services describe kalyanam-frontend --region=us-central1
```

### View Logs
```bash
# Recent logs
gcloud run services logs read kalyanam-frontend --region=us-central1 --limit=20

# Live logs
gcloud run services logs tail kalyanam-frontend --region=us-central1
```

### Update to New Version
```bash
# Update image_uri in terraform.tfvars
nano terraform.tfvars

# Apply changes
terraform apply
```

### Delete Everything
```bash
terraform destroy
```

## Troubleshooting

### "Permission denied"
```bash
# Re-authenticate
gcloud auth application-default login

# Verify project
gcloud config get-value project
```

### "Service not accessible"
```bash
# Check service status
gcloud run services describe kalyanam-frontend --region=us-central1

# Verify public access
gcloud run services get-iam-policy kalyanam-frontend --region=us-central1
```

### "Image pull failed"
```bash
# Verify image exists
docker pull docker.io/dockerrajmanda/kalyanam:405

# Check Cloud Run logs
gcloud run services logs read kalyanam-frontend --region=us-central1
```

## Next Steps

### 1. Custom Domain
```bash
gcloud run domain-mappings create \
  --service=kalyanam-frontend \
  --domain=www.kalyanam.com \
  --region=us-central1
```

### 2. Connect to Backend
Update Angular environment to point to backend API:
```typescript
// src/environments/environment.prod.ts
export const environment = {
  production: true,
  apiUrl: 'https://rsvp-backend-xxxxx-uc.a.run.app'
};
```

### 3. Enable Monitoring
```bash
# View metrics in Cloud Console
gcloud run services describe kalyanam-frontend --region=us-central1 --format="value(status.url)"
```

### 4. Set Up CI/CD
See `.github/workflows/` for GitHub Actions examples.

## Cost Expectations

**Free Tier**: 2 million requests/month
- 10K requests/month: **$0** (free tier)
- 500K requests/month: **~$2-3** per month
- 5M requests/month: **~$12-18** per month

**Scale to Zero**: When no traffic, you pay $0!

## Resources

- 📚 [Full README](./README.md)
- 🌐 [Cloud Run Docs](https://cloud.google.com/run/docs)
- 💬 [Terraform Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service)

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                    Internet                         │
└─────────────────┬───────────────────────────────────┘
                  │
                  │ HTTPS (managed certificate)
                  ▼
┌─────────────────────────────────────────────────────┐
│         Google Cloud Run (us-central1)              │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  Service: kalyanam-frontend                   │ │
│  │  ┌─────────────────────────────────────────┐ │ │
│  │  │  Container (auto-scaling 0-100)         │ │ │
│  │  │  ┌───────────────────────────────────┐ │ │ │
│  │  │  │  NGINX (port 80)                  │ │ │ │
│  │  │  │  └─> Angular SPA                  │ │ │ │
│  │  │  │      (Static Files)               │ │ │ │
│  │  │  └───────────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────────┘ │ │
│  │  Identity: kalyanam-frontend-sa               │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Success Indicators

✅ `terraform apply` completes without errors
✅ Service URL is accessible in browser
✅ Angular application loads correctly
✅ All routes work (SPA routing via NGINX)
✅ No errors in Cloud Run logs

## Getting Help

**Can't find the service URL?**
```bash
terraform output service_url
```

**Want to see all outputs?**
```bash
terraform output
```

**Need to start over?**
```bash
terraform destroy
terraform apply
```

**Questions?**
- Check [README.md](./README.md) for detailed documentation
- Review [Troubleshooting section](./README.md#troubleshooting)
- Check Cloud Run logs for errors

---

**Happy Deploying! 🚀**
