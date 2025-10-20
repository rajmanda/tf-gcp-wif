# Step-by-Step Deployment Instructions

Follow these steps to deploy the Kalyanam Angular application to Google Cloud Run using Terraform.

## Prerequisites Completed ✓

Based on your requirements, the following is already configured:

- ✅ Docker Hub registry (docker.io/dockerrajmanda/kalyanam)
- ✅ No secrets needed (static frontend)
- ✅ Service account will be created (kalyanam-frontend-sa)
- ✅ Public access configured
- ✅ Region: us-central1
- ✅ No environment variables needed

## Step 1: Verify Your Environment

### 1.1 Check GCP Authentication

```bash
# Login to GCP (if not already authenticated)
gcloud auth login

# Set your project
gcloud config set project properties-app-418208

# Set up application default credentials for Terraform
gcloud auth application-default login
```

### 1.2 Verify Terraform Installation

```bash
# Check Terraform version (should be >= 1.0)
terraform version

# If not installed, install it:
# macOS:
brew install terraform

# Linux:
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### 1.3 Verify Docker Image Accessibility

```bash
# Test that the image can be pulled
docker pull docker.io/dockerrajmanda/kalyanam:405

# Verify it runs locally
docker run -d -p 8080:80 --name test-kalyanam docker.io/dockerrajmanda/kalyanam:405

# Test in browser or curl
curl -I http://localhost:8080

# Clean up
docker stop test-kalyanam
docker rm test-kalyanam
```

## Step 2: Navigate to Terraform Directory

```bash
# Navigate to the terraform directory
cd /app/terraform

# Verify all files are present
ls -la

# You should see:
# - All .tf files (001 through 006)
# - variables.tf, terraform.tfvars, outputs.tf
# - Documentation files (.md)
# - DEPLOY.sh script
```

## Step 3: Review Configuration

### 3.1 Check terraform.tfvars

```bash
cat terraform.tfvars
```

Expected output:
```hcl
project_id   = "properties-app-418208"
region       = "us-central1"
service_name = "kalyanam-frontend"
image_uri    = "docker.io/dockerrajmanda/kalyanam:405"
```

### 3.2 (Optional) Update Image Tag

If you want to use a different image tag:

```bash
# Edit terraform.tfvars
nano terraform.tfvars

# Change the image_uri line to your desired tag
image_uri = "docker.io/dockerrajmanda/kalyanam:YOUR_TAG"

# Save and exit (Ctrl+X, then Y, then Enter)
```

## Step 4: Deploy with Terraform

### Option A: Automated Deployment (Recommended)

```bash
# Make the script executable (if not already)
chmod +x DEPLOY.sh

# Run the deployment script
./DEPLOY.sh
```

The script will:
1. Check all prerequisites
2. Initialize Terraform
3. Show you the plan
4. Ask for confirmation
5. Deploy the service
6. Display the service URL

### Option B: Manual Deployment

```bash
# Step 4.1: Initialize Terraform
terraform init

# Expected output:
# - Initializing the backend...
# - Initializing provider plugins...
# - Terraform has been successfully initialized!

# Step 4.2: Validate configuration
terraform validate

# Expected output:
# Success! The configuration is valid.

# Step 4.3: Create execution plan
terraform plan

# Review the plan carefully. You should see:
# Plan: 5 to add, 0 to change, 0 to destroy.
# 
# Resources to be created:
# - google_project_service.run_api
# - google_project_service.iam_api
# - google_service_account.kalyanam_frontend_sa
# - google_cloud_run_v2_service.kalyanam_frontend
# - google_cloud_run_v2_service_iam_member.public_access

# Step 4.4: Apply the configuration
terraform apply

# Type 'yes' when prompted

# Wait for completion (2-3 minutes)
```

## Step 5: Verify Deployment

### 5.1 Check Terraform Outputs

```bash
# View all outputs
terraform output

# Get the service URL
SERVICE_URL=$(terraform output -raw service_url)
echo "Service URL: $SERVICE_URL"

# Example output:
# service_url = "https://kalyanam-frontend-abc123xyz-uc.a.run.app"
# service_name = "kalyanam-frontend"
# service_account_email = "kalyanam-frontend-sa@properties-app-418208.iam.gserviceaccount.com"
# region = "us-central1"
```

### 5.2 Test the Service

```bash
# Test with curl (should return HTTP 200)
curl -I $SERVICE_URL

# Expected output:
# HTTP/2 200
# content-type: text/html
# ...

# Get the full page
curl $SERVICE_URL

# Should return HTML content with Angular app
```

### 5.3 Open in Browser

```bash
# macOS
open $SERVICE_URL

# Linux
xdg-open $SERVICE_URL

# Windows WSL
explorer.exe $SERVICE_URL

# Or manually copy the URL and paste in browser
echo $SERVICE_URL
```

### 5.4 Verify in GCP Console

```bash
# Open Cloud Run console
gcloud run services describe kalyanam-frontend --region=us-central1

# Or view in web console:
# https://console.cloud.google.com/run?project=properties-app-418208
```

## Step 6: Test the Application

### 6.1 Basic Functionality Tests

1. **Homepage loads**: ✓
2. **Navigation works**: ✓
3. **All routes accessible**: ✓
4. **Static assets load (CSS, JS, images)**: ✓
5. **No console errors**: ✓

### 6.2 Angular Routing Tests

Test SPA routing (all routes should work, not return 404):

```bash
# Test different routes (replace URL with your actual service URL)
curl -I $SERVICE_URL/
curl -I $SERVICE_URL/some-route
curl -I $SERVICE_URL/another-route

# All should return 200 (NGINX serves index.html for all routes)
```

## Step 7: View Logs (Optional)

```bash
# View recent logs
gcloud run services logs read kalyanam-frontend --region=us-central1 --limit=20

# Follow logs in real-time
gcloud run services logs tail kalyanam-frontend --region=us-central1

# Press Ctrl+C to stop tailing
```

## Step 8: Monitor the Service

```bash
# Check service details
gcloud run services describe kalyanam-frontend \
  --region=us-central1 \
  --format=json

# View service URL directly
gcloud run services describe kalyanam-frontend \
  --region=us-central1 \
  --format="value(status.url)"

# Check service status
gcloud run services describe kalyanam-frontend \
  --region=us-central1 \
  --format="value(status.conditions[0].status)"

# Should output: True (meaning service is healthy)
```

## Step 9: (Optional) Set Up Custom Domain

If you want to use a custom domain like `www.kalyanam.com`:

```bash
# Map domain to Cloud Run service
gcloud run domain-mappings create \
  --service=kalyanam-frontend \
  --domain=www.kalyanam.com \
  --region=us-central1

# Follow the instructions to add DNS records
# Cloud Run will provide the required DNS records
```

## Step 10: Save Service URL

```bash
# Save the service URL to a file for future reference
terraform output -raw service_url > service_url.txt

echo "Service URL saved to service_url.txt"

# Display it
cat service_url.txt
```

## Common Operations After Deployment

### Update to New Version

```bash
# 1. Build and push new Docker image
docker build -t dockerrajmanda/kalyanam:406 .
docker push dockerrajmanda/kalyanam:406

# 2. Update terraform.tfvars
sed -i 's/:405/:406/' terraform.tfvars
# Or manually edit: nano terraform.tfvars

# 3. Deploy the update
terraform apply

# Cloud Run will perform a rolling update (zero downtime)
```

### Scale Configuration

By default, Cloud Run auto-scales from 0 to 100 instances. To limit:

```bash
# Edit 005-deploy-cloud-run.tf
nano 005-deploy-cloud-run.tf

# Add in the template block:
    scaling {
      min_instance_count = 0  # Can be 0 or higher
      max_instance_count = 10  # Limit to 10 instances
    }

# Save and apply
terraform apply
```

### View Metrics

```bash
# View in web console
echo "https://console.cloud.google.com/run/detail/us-central1/kalyanam-frontend/metrics?project=properties-app-418208"

# Or use gcloud
gcloud run services describe kalyanam-frontend \
  --region=us-central1 \
  --format="table(status.url,status.latestReadyRevisionName,status.latestCreatedRevisionName)"
```

## Troubleshooting

### Issue: "Permission denied"

```bash
# Solution: Re-authenticate
gcloud auth login
gcloud auth application-default login

# Verify correct account
gcloud auth list
```

### Issue: "Service fails to deploy"

```bash
# Check logs for errors
gcloud run services logs read kalyanam-frontend --region=us-central1

# Verify image exists
docker pull docker.io/dockerrajmanda/kalyanam:405

# Check service status
gcloud run services describe kalyanam-frontend --region=us-central1
```

### Issue: "404 errors on Angular routes"

```bash
# Verify nginx.conf in the Docker image has:
# try_files $uri $uri/ /index.html;

# Test locally first
docker run -d -p 8080:80 docker.io/dockerrajmanda/kalyanam:405
curl -I http://localhost:8080/some-route
# Should return 200, not 404
```

### Issue: "Terraform state locked"

```bash
# If Terraform gets interrupted, you might see a state lock error
# Wait 5 minutes and try again, or force unlock (use carefully):
terraform force-unlock LOCK_ID
```

## Cleanup (If Needed)

To completely remove the deployment:

```bash
# Destroy all resources
terraform destroy

# Type 'yes' when prompted

# This will delete:
# - Cloud Run service
# - Service account
# - IAM bindings
# (API enablements remain for other services)
```

## Next Steps

1. ✅ Service is deployed and accessible
2. ⚠️  (Optional) Set up custom domain
3. ⚠️  (Optional) Configure CI/CD for automatic deployments
4. ⚠️  (Optional) Set up monitoring alerts
5. ⚠️  (Optional) Connect to backend API (if applicable)

## Summary

You have successfully:

- ✅ Deployed Kalyanam Angular app to Cloud Run
- ✅ Created a dedicated service account
- ✅ Enabled public access
- ✅ Configured auto-scaling
- ✅ Set up health checks
- ✅ Got a public HTTPS endpoint

**Your application is now live and accessible!**

Service URL: Run `terraform output -raw service_url` to get your URL

## Need Help?

- 📚 Check [README.md](./README.md) for detailed documentation
- 🚀 Review [QUICK_START.md](./QUICK_START.md) for quick reference
- 📋 Use [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) for verification
- 🔄 See [MIGRATION.md](./MIGRATION.md) for K8s comparison

## Cost Monitoring

```bash
# Check billing in console
echo "https://console.cloud.google.com/billing/projects/properties-app-418208"

# Set up budget alerts (recommended)
# https://console.cloud.google.com/billing/budgets?project=properties-app-418208
```

Remember: Cloud Run scales to zero when idle, so you only pay for actual usage!

---

**Deployment Complete! 🎉**
