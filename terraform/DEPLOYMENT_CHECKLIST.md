# Deployment Checklist - Kalyanam Frontend to Cloud Run

Use this checklist to ensure a smooth deployment.

## Pre-Deployment

### GCP Setup
- [ ] GCP account created
- [ ] Billing enabled on project
- [ ] Project ID noted: `properties-app-418208` (or your project)
- [ ] gcloud CLI installed
- [ ] Authenticated: `gcloud auth login`
- [ ] Application default credentials set: `gcloud auth application-default login`

### Local Environment
- [ ] Terraform installed (version >= 1.0)
- [ ] Git installed
- [ ] Repository cloned
- [ ] Checked out correct branch: `feature/deploy-kalyanam-as-cloudrun`

### Docker Image
- [ ] Docker image available: `docker.io/dockerrajmanda/kalyanam:405`
- [ ] Image tag is correct and tested
- [ ] Image is publicly accessible (or credentials configured)

### IAM Permissions
- [ ] Account has required roles:
  - [ ] `roles/owner` OR
  - [ ] `roles/iam.serviceAccountAdmin`
  - [ ] `roles/run.admin`
  - [ ] `roles/resourcemanager.projectIamAdmin`

## Configuration Review

### terraform.tfvars
- [ ] `project_id` is correct
- [ ] `region` is set to desired region (default: us-central1)
- [ ] `service_name` is appropriate (default: kalyanam-frontend)
- [ ] `image_uri` points to correct image and tag

### Terraform Files
- [ ] All `.tf` files present in terraform directory:
  - [ ] `001-provider.tf`
  - [ ] `002-enable-apis.tf`
  - [ ] `003-service-account.tf`
  - [ ] `004-service-account-permissions.tf`
  - [ ] `005-deploy-cloud-run.tf`
  - [ ] `006-permissions-for-cloud-run.tf`
  - [ ] `variables.tf`
  - [ ] `outputs.tf`

## Deployment Steps

### Initialize
- [ ] Run: `terraform init`
- [ ] Verify: No errors in initialization
- [ ] Verify: Provider plugins downloaded

### Plan
- [ ] Run: `terraform plan`
- [ ] Review: Expected resources:
  - [ ] 2 API enablements (Cloud Run, IAM)
  - [ ] 1 service account
  - [ ] 1 Cloud Run service
  - [ ] 1 IAM policy binding
- [ ] No unexpected deletions or replacements

### Apply
- [ ] Run: `terraform apply`
- [ ] Type `yes` when prompted
- [ ] Wait for completion (2-3 minutes)
- [ ] No errors during apply

## Post-Deployment Validation

### Terraform Outputs
- [ ] Service URL displayed
- [ ] Service name displayed
- [ ] Service account email displayed
- [ ] Region displayed

### Service Validation
- [ ] Service URL accessible via curl: `curl -I $(terraform output -raw service_url)`
- [ ] Returns HTTP 200 OK
- [ ] Service accessible in browser
- [ ] Angular application loads correctly
- [ ] No console errors in browser

### Cloud Run Console
- [ ] Service visible in GCP Console
- [ ] Service shows as "Healthy"
- [ ] No errors in logs
- [ ] Metrics show successful requests

### Functional Tests
- [ ] Homepage loads
- [ ] Navigation works
- [ ] All routes accessible (SPA routing)
- [ ] Static assets load (CSS, JS, images)
- [ ] OAuth/Authentication works (if applicable)

## Post-Deployment Configuration

### Optional: Custom Domain
- [ ] Domain mapping created
- [ ] DNS records updated
- [ ] SSL certificate provisioned
- [ ] Custom domain accessible

### Optional: Backend Integration
- [ ] Backend API URL configured in Angular environment
- [ ] CORS configured on backend
- [ ] API calls successful
- [ ] Authentication flows work end-to-end

### Optional: Monitoring
- [ ] Cloud Monitoring enabled
- [ ] Alerts configured
- [ ] Log-based metrics created
- [ ] Uptime checks configured

### Optional: CI/CD
- [ ] GitHub Actions workflow configured
- [ ] Secrets added to GitHub
- [ ] Test deployment from CI/CD
- [ ] Rollback procedure documented

## Security Review

- [ ] Service account has minimal permissions
- [ ] Public access is intentional (allUsers)
- [ ] HTTPS enabled (automatic with Cloud Run)
- [ ] No secrets in container image
- [ ] No sensitive data in environment variables

## Documentation

- [ ] README.md reviewed
- [ ] QUICK_START.md accessible
- [ ] Deployment notes recorded
- [ ] Service URL documented
- [ ] Rollback procedure documented

## Cost Management

- [ ] Budget alerts configured
- [ ] Cost estimation reviewed
- [ ] Free tier limits understood
- [ ] Scaling limits appropriate

## Troubleshooting Preparation

- [ ] Know how to view logs: `gcloud run services logs read kalyanam-frontend --region=us-central1`
- [ ] Know how to check service status: `gcloud run services describe kalyanam-frontend --region=us-central1`
- [ ] Know how to rollback: Update image_uri and `terraform apply`
- [ ] Emergency contacts identified

## Sign-Off

- [ ] All critical items completed
- [ ] Service tested and verified
- [ ] Team notified of new deployment
- [ ] Documentation updated

---

**Deployment Date**: _______________

**Deployed By**: _______________

**Service URL**: _______________

**Notes**: 

_______________________________________________

_______________________________________________

_______________________________________________
