# RSVP Backend - GCP Cloud Run Deployment

This Terraform configuration deploys an RSVP backend application to Google Cloud Run with supporting infrastructure including GCS bucket for file storage and Secret Manager integration.

## Architecture Overview

- **Cloud Run Service**: Hosts the Spring Boot RSVP backend application
- **GCS Bucket**: Stores uploaded files with CORS enabled for frontend access
- **Secret Manager**: Securely manages MongoDB URI and Gmail credentials
- **Service Account**: Dedicated service account with minimal required permissions
- **IAM Policies**: Proper access controls for all resources

## Prerequisites

### 1. GCP Project Setup
- Active GCP project: `properties-app-418208`
- Billing enabled on the project
- Required APIs will be enabled automatically by Terraform

### 2. Required IAM Permissions
Your GCP account must have the following roles:
- `roles/owner` OR the following combined roles:
  - `roles/iam.serviceAccountAdmin`
  - `roles/run.admin`
  - `roles/storage.admin`
  - `roles/secretmanager.admin`
  - `roles/resourcemanager.projectIamAdmin`

### 3. Required Secrets in GCP Secret Manager
**CRITICAL**: Before running `terraform apply`, create these secrets in GCP Secret Manager:

```bash
# Create MongoDB URI secret
echo -n "your-mongodb-connection-string" | gcloud secrets create mongodb-uri --data-file=-

# Create Gmail username secret
echo -n "your-gmail-username@gmail.com" | gcloud secrets create gmail-username --data-file=-

# Create Gmail password secret (use App Password, not regular password)
echo -n "your-gmail-app-password" | gcloud secrets create gmail-password --data-file=-
```

### 4. Docker Image
Ensure the Docker image is accessible:
- Image: `docker.io/dockerrajmanda/rsvpbackend:122`
- Must be publicly accessible or credentials configured

### 5. Terraform Installation
Install Terraform (version >= 1.0):
```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

## Configuration

### Variables
All configurable variables are defined in `terraform.tfvars`:

```hcl
project_id      = "properties-app-418208"
region          = "us-central1"
image_uri       = "docker.io/dockerrajmanda/rsvpbackend:122"
gcs_bucket_name = "kalyanam_bucket"
frontend_url    = "http://localhost:4200,https://staging.kalyanam.com,https://www.kalyanam.com"
```

### CORS Configuration
The `frontend_url` variable accepts comma-separated origins. These will be:
- Split and applied to the GCS bucket CORS policy
- Passed as-is to the Cloud Run service for Spring Boot CORS configuration

## Deployment Steps

### 1. Initialize Terraform
```bash
cd /app
terraform init
```

### 2. Review the Plan
```bash
terraform plan
```
Review the planned changes carefully. You should see:
- 3 API enablements
- 1 service account
- 4 IAM member bindings
- 1 GCS bucket
- 1 Cloud Run service
- 1 Cloud Run IAM policy

### 3. Apply Configuration
```bash
terraform apply
```
Type `yes` when prompted to confirm.

### 4. Verify Deployment
After successful deployment, Terraform will output:
- `service_url`: The URL of your deployed Cloud Run service
- `gcs_bucket_name`: The name of your GCS bucket
- `gcs_bucket_url`: The URL of your GCS bucket
- `service_account_email`: The service account email

### 5. Test the Deployment
```bash
# Get the service URL
SERVICE_URL=$(terraform output -raw service_url)

# Test health endpoint
curl $SERVICE_URL/actuator/health
```

## Resource Details

### Cloud Run Service
- **Name**: `rsvp-backend`
- **Region**: `us-central1`
- **Port**: `8080`
- **Access**: Public (unauthenticated)
- **Resources**: 1 CPU, 512Mi memory
- **Health Checks**: Startup and liveness probes on `/actuator/health`

### Environment Variables
The Cloud Run service receives:
- `GCS_BUCKET_NAME`: Name of the GCS bucket
- `SPRING_DATA_MONGODB_URI`: MongoDB connection string (from Secret Manager)
- `SPRING_MAIL_USERNAME`: Gmail username (from Secret Manager)
- `SPRING_MAIL_PASSWORD`: Gmail app password (from Secret Manager)
- `APP_CORS_ALLOWED_ORIGINS`: Comma-separated list of allowed origins

### GCS Bucket
- **Name**: `kalyanam_bucket`
- **Location**: `US` (multi-region)
- **Versioning**: Enabled
- **CORS**: Configured for all specified frontend origins

## Maintenance

### Update Docker Image
1. Build and push new image with a new tag
2. Update `image_uri` in `terraform.tfvars`
3. Run `terraform apply`

### Update Secrets
```bash
# Update a secret
echo -n "new-secret-value" | gcloud secrets versions add mongodb-uri --data-file=-

# Secrets are automatically picked up by Cloud Run (using "latest" version)
```

### Update Frontend URLs
1. Update `frontend_url` in `terraform.tfvars`
2. Run `terraform apply`

### View Logs
```bash
# View Cloud Run logs
gcloud run services logs read rsvp-backend --region=us-central1 --limit=50

# Follow logs in real-time
gcloud run services logs tail rsvp-backend --region=us-central1
```

## Troubleshooting

### Secret Not Found Error
**Error**: `Secret [secret-name] not found`

**Solution**: Create the secret in Secret Manager before running terraform apply:
```bash
gcloud secrets create mongodb-uri --data-file=-
# Then paste the value and press Ctrl+D
```

### Permission Denied Errors
**Error**: `Permission denied` or `403 Forbidden`

**Solution**: Ensure your account has the required IAM roles listed in Prerequisites.

### Bucket Name Already Exists
**Error**: `Bucket name already exists`

**Solution**: 
- If you own the bucket: Import it into Terraform
- Otherwise: Change `gcs_bucket_name` in `terraform.tfvars` to a globally unique name

### Health Check Failures
**Error**: Cloud Run service fails health checks

**Solution**:
1. Verify your Spring Boot application exposes `/actuator/health` endpoint
2. Ensure the application listens on port 8080
3. Check Cloud Run logs for startup errors

### CORS Errors in Frontend
**Error**: CORS policy blocking requests

**Solution**:
1. Verify `frontend_url` includes all domains (including protocol)
2. Ensure no trailing slashes in URLs
3. Check Cloud Run logs to verify APP_CORS_ALLOWED_ORIGINS is set correctly

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Warning**: This will delete:
- The Cloud Run service
- The GCS bucket and all its contents
- The service account
- All IAM bindings

Secrets in Secret Manager will NOT be deleted by Terraform.

## Security Considerations

1. **Public Access**: The Cloud Run service allows unauthenticated access (`allUsers`). Consider implementing authentication if needed.

2. **Secret Management**: Secrets are managed by GCP Secret Manager with proper IAM access controls.

3. **Service Account**: Uses a dedicated service account with minimal required permissions.

4. **Bucket Access**: The service account has `objectAdmin` role on the GCS bucket, allowing read/write operations.

## Cost Estimation

Approximate monthly costs (as of 2025):
- Cloud Run: ~$5-50 (depending on traffic)
- GCS Storage: ~$0.02/GB
- Secret Manager: $0.06 per secret per month + $0.03 per 10,000 access operations
- **Total**: Estimated $10-100/month for small to medium traffic

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review Cloud Run logs: `gcloud run services logs read rsvp-backend`
3. Verify all prerequisites are met
4. Check Terraform state: `terraform show`

## Version Information

- Terraform: >= 1.0
- Google Provider: >= 7.7.0
- Cloud Run: v2 API
