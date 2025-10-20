# Terraform Configuration Summary

## Overview
This directory contains Terraform configuration to deploy the Kalyanam Angular application to Google Cloud Run.

## File Structure

```
terraform/
├── 001-provider.tf                    # Terraform and GCP provider configuration
├── 002-enable-apis.tf                 # Enable required GCP APIs (Cloud Run, IAM)
├── 003-service-account.tf             # Create service account for Cloud Run
├── 004-service-account-permissions.tf # IAM permissions (minimal for static site)
├── 005-deploy-cloud-run.tf            # Main Cloud Run service definition
├── 006-permissions-for-cloud-run.tf   # Public access configuration (allUsers)
├── variables.tf                       # Variable definitions
├── terraform.tfvars                   # Variable values (customize here)
├── outputs.tf                         # Output definitions (service URL, etc.)
├── .gitignore                         # Ignore Terraform state files
├── README.md                          # Comprehensive documentation
├── QUICK_START.md                     # 5-minute deployment guide
├── DEPLOYMENT_CHECKLIST.md            # Pre/post-deployment checklist
├── MIGRATION.md                       # K8s to Cloud Run migration guide
├── DEPLOY.sh                          # Automated deployment script
└── SUMMARY.md                         # This file
```

## Quick Commands

### Deploy
```bash
# Option 1: Manual
terraform init
terraform plan
terraform apply

# Option 2: Automated
./DEPLOY.sh
```

### Update
```bash
# Edit terraform.tfvars to change image tag
nano terraform.tfvars

# Apply changes
terraform apply
```

### Destroy
```bash
terraform destroy
```

### View Outputs
```bash
terraform output
terraform output -raw service_url
```

## Configuration

### Key Variables (terraform.tfvars)

| Variable | Default | Description |
|----------|---------|-------------|
| project_id | properties-app-418208 | GCP project ID |
| region | us-central1 | Deployment region |
| service_name | kalyanam-frontend | Cloud Run service name |
| image_uri | docker.io/dockerrajmanda/kalyanam:405 | Docker image |

### To Customize

1. Edit `terraform.tfvars`
2. Run `terraform apply`

## Resources Created

1. **Cloud Run Service** (`kalyanam-frontend`)
   - Container: Docker image from Docker Hub
   - Port: 80 (NGINX)
   - Resources: 1 CPU, 512Mi memory
   - Scaling: 0-100 instances (automatic)
   - Health checks: HTTP GET on `/`

2. **Service Account** (`kalyanam-frontend-sa`)
   - Minimal permissions
   - Used by Cloud Run service

3. **IAM Policy**
   - Allows public access (allUsers)
   - Role: run.invoker

4. **API Enablement**
   - Cloud Run API
   - IAM API

## Outputs

After deployment, Terraform provides:

- `service_url`: The public URL of your application
- `service_name`: The Cloud Run service name
- `service_account_email`: The service account email
- `region`: The deployment region

## Common Operations

### View Logs
```bash
gcloud run services logs read kalyanam-frontend --region=us-central1 --limit=50
gcloud run services logs tail kalyanam-frontend --region=us-central1
```

### Check Service Status
```bash
gcloud run services describe kalyanam-frontend --region=us-central1
```

### Update to New Version
```bash
# 1. Build and push new image
docker build -t dockerrajmanda/kalyanam:406 .
docker push dockerrajmanda/kalyanam:406

# 2. Update terraform.tfvars
sed -i 's/:405/:406/' terraform.tfvars

# 3. Deploy
terraform apply
```

### Test Service
```bash
# HTTP check
curl -I $(terraform output -raw service_url)

# Full page
curl $(terraform output -raw service_url)

# Open in browser
open $(terraform output -raw service_url)  # macOS
xdg-open $(terraform output -raw service_url)  # Linux
```

## Security

### Service Account
- Dedicated service account with minimal permissions
- No additional GCP service access granted
- Follows principle of least privilege

### Public Access
- Service is publicly accessible (allUsers)
- Appropriate for public-facing frontend
- HTTPS enabled automatically

### Secrets
- No secrets required (static site)
- No environment variables with sensitive data

## Cost Optimization

### Auto-scaling to Zero
Cloud Run automatically scales to zero when no traffic:
- Zero requests = $0 cost
- Automatic scale-up on first request

### Free Tier
- 2 million requests per month (free)
- 360,000 vCPU-seconds per month (free)
- 180,000 GiB-seconds of memory per month (free)

### Cost Control
To limit maximum instances:
```hcl
# In 005-deploy-cloud-run.tf, add:
scaling {
  max_instance_count = 10
}
```

## Troubleshooting

### Common Issues

**Problem**: Permission denied
**Solution**: 
```bash
gcloud auth application-default login
```

**Problem**: Image pull failed
**Solution**: 
```bash
# Verify image exists
docker pull docker.io/dockerrajmanda/kalyanam:405
```

**Problem**: Service not accessible
**Solution**: 
```bash
# Check IAM policy
gcloud run services get-iam-policy kalyanam-frontend --region=us-central1
```

**Problem**: Angular routes return 404
**Solution**: Verify nginx.conf has:
```nginx
try_files $uri $uri/ /index.html;
```

## Best Practices

1. **Version Control**: Commit terraform.tfvars to Git (no secrets)
2. **Image Tags**: Use specific tags, not `latest`
3. **Testing**: Test locally before deploying: `docker run -p 8080:80 IMAGE`
4. **Monitoring**: Check logs regularly: `gcloud run services logs read`
5. **Updates**: Use `terraform plan` before `apply`

## Integration with Backend

If connecting to the RSVP backend:

1. Get backend URL:
   ```bash
   # From backend terraform
   cd ../rsvp-backend-terraform
   terraform output -raw service_url
   ```

2. Update Angular environment:
   ```typescript
   // src/environments/environment.prod.ts
   export const environment = {
     production: true,
     apiUrl: 'https://rsvp-backend-xxx.a.run.app'
   };
   ```

3. Rebuild image and deploy:
   ```bash
   docker build -t dockerrajmanda/kalyanam:406 .
   docker push dockerrajmanda/kalyanam:406
   
   # Update terraform.tfvars
   terraform apply
   ```

## Documentation

- **README.md**: Comprehensive guide with all details
- **QUICK_START.md**: 5-minute deployment guide
- **DEPLOYMENT_CHECKLIST.md**: Pre/post-deployment checklist
- **MIGRATION.md**: Migration from Kubernetes to Cloud Run

## Support

For issues:
1. Check logs: `gcloud run services logs read kalyanam-frontend`
2. Review README.md troubleshooting section
3. Verify prerequisites: `./DEPLOY.sh` does this automatically
4. Check Terraform state: `terraform show`

## Next Steps

After deployment:
1. ✅ Test the service URL
2. ✅ Verify Angular app loads
3. ✅ Check all routes work
4. ⚠️  Set up custom domain (optional)
5. ⚠️  Configure monitoring alerts (optional)
6. ⚠️  Set up CI/CD pipeline (optional)

## Version Requirements

- Terraform: >= 1.0
- Google Provider: >= 7.7.0
- gcloud CLI: Latest version recommended

## Additional Resources

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Angular Deployment Guide](https://angular.io/guide/deployment)

---

**Last Updated**: 2025-08-20
**Terraform Version**: >= 1.0
**Google Provider Version**: >= 7.7.0
