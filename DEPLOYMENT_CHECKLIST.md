# Pre-Deployment Checklist

Use this checklist before deploying your infrastructure to ensure everything is properly configured.

## ✅ Prerequisites Verification

### GCP Account & Project
- [ ] GCP project `properties-app-418208` exists and is active
- [ ] Billing is enabled on the project
- [ ] You have the required IAM permissions (Owner or equivalent roles)
- [ ] You are authenticated with GCP CLI: `gcloud auth login`
- [ ] Your project is set: `gcloud config set project properties-app-418208`

### Required Secrets
Create these secrets **before** running Terraform:

- [ ] **MongoDB URI** secret created:
  ```bash
  echo -n "mongodb+srv://username:password@cluster.mongodb.net/dbname" | \
  gcloud secrets create mongodb-uri --data-file=- --project=properties-app-418208
  ```

- [ ] **Gmail Username** secret created:
  ```bash
  echo -n "your-email@gmail.com" | \
  gcloud secrets create gmail-username --data-file=- --project=properties-app-418208
  ```

- [ ] **Gmail App Password** secret created:
  ```bash
  echo -n "your-16-char-app-password" | \
  gcloud secrets create gmail-password --data-file=- --project=properties-app-418208
  ```

- [ ] Verify secrets exist:
  ```bash
  gcloud secrets list --project=properties-app-418208
  ```

### Docker Image
- [ ] Docker image `docker.io/dockerrajmanda/rsvpbackend:122` exists
- [ ] Image is publicly accessible OR you have configured GCP with Docker credentials
- [ ] Image contains a Spring Boot application that:
  - [ ] Listens on port 8080
  - [ ] Exposes `/actuator/health` endpoint
  - [ ] Reads environment variables: `SPRING_DATA_MONGODB_URI`, `SPRING_MAIL_USERNAME`, `SPRING_MAIL_PASSWORD`, `APP_CORS_ALLOWED_ORIGINSINS`, `GCS_BUCKET_NAME`

### Terraform Setup
- [ ] Terraform is installed (v1.0 or higher): `terraform --version`
- [ ] You have reviewed `terraform.tfvars` and confirmed all values are correct
- [ ] GCS bucket name `kalyanam_bucket` is globally unique (or will be created fresh)

### Network & DNS (Optional)
- [ ] Frontend domains are ready: `staging.kalyanam.com`, `www.kalyanam.com`
- [ ] You have DNS access to point domains to Cloud Run service (if needed)

## 🚀 Deployment Steps

### Step 1: Initialize Terraform
```bash
cd /app
terraform init
```
- [ ] Initialization completed successfully
- [ ] Provider plugins downloaded

### Step 2: Validate Configuration
```bash
terraform validate
```
- [ ] Configuration is valid
- [ ] No syntax errors

### Step 3: Plan Deployment
```bash
terraform plan -out=tfplan
```
- [ ] Plan generated successfully
- [ ] Review shows approximately 11-12 resources to be created:
  - [ ] 3 API enablements (Cloud Run, Secret Manager, IAM)
  - [ ] 1 Service Account
  - [ ] 4 IAM member bindings (3 secret accessors + 1 bucket access)
  - [ ] 1 GCS Bucket
  - [ ] 1 Cloud Run Service
  - [ ] 1 Cloud Run IAM policy
- [ ] No unexpected deletions or modifications
- [ ] All secret references are correct

### Step 4: Apply Configuration
```bash
terraform apply tfplan
```
- [ ] Type `yes` to confirm
- [ ] Deployment completed without errors
- [ ] All resources created successfully

### Step 5: Capture Outputs
```bash
terraform output
```
- [ ] Record the `service_url` (your Cloud Run endpoint)
- [ ] Record the `gcs_bucket_name`
- [ ] Record the `service_account_email`

## ✅ Post-Deployment Verification

### Test Backend Health
```bash
# Get service URL
SERVICE_URL=$(terraform output -raw service_url)

# Test health endpoint
curl $SERVICE_URL/actuator/health
```
- [ ] Health check returns HTTP 200
- [ ] Response shows status: "UP" or similar

### Test Cloud Run Service
```bash
# View recent logs
gcloud run services logs read rsvp-backend --region=us-central1 --limit=20
```
- [ ] No critical errors in logs
- [ ] Application started successfully
- [ ] Environment variables loaded correctly

### Test GCS Bucket
```bash
# List bucket (should be empty initially)
gsutil ls gs://kalyanam_bucket/
```
- [ ] Bucket is accessible
- [ ] CORS configuration is set

### Test Frontend Integration
- [ ] Update frontend to use the new `service_url`
- [ ] Test API calls from frontend
- [ ] Verify CORS is working (no CORS errors in browser console)
- [ ] Test file uploads to GCS bucket
- [ ] Verify images/files are accessible from frontend

## 🔍 Common Issues & Solutions

### Issue: "Secret not found"
**Solution**: Create the secret in Secret Manager:
```bash
gcloud secrets create mongodb-uri --data-file=-
# Paste your MongoDB URI and press Ctrl+D
```

### Issue: "Permission denied"
**Solution**: Grant yourself the required roles:
```bash
gcloud projects add-iam-policy-binding properties-app-418208 \
  --member="user:your-email@gmail.com" \
  --role="roles/owner"
```

### Issue: "Bucket already exists"
**Solution**: Either import the existing bucket or change the bucket name in `terraform.tfvars`

### Issue: Health checks failing
**Solution**: 
1. Verify `/actuator/health` endpoint exists
2. Ensure app listens on port 8080
3. Check logs: `gcloud run services logs tail rsvp-backend --region=us-central1`

### Issue: CORS errors
**Solution**:
1. Verify `frontend_url` in `terraform.tfvars` includes all domains with correct protocol
2. No trailing slashes in URLs
3. Restart Cloud Run if needed: `gcloud run services update rsvp-backend --region=us-central1`

## 📊 Monitoring & Maintenance

### View Logs
```bash
# Tail logs in real-time
gcloud run services logs tail rsvp-backend --region=us-central1

# Read last 100 lines
gcloud run services logs read rsvp-backend --region=us-central1 --limit=100
```

### Monitor Resources
- [ ] Cloud Run Dashboard: https://console.cloud.google.com/run
- [ ] Cloud Storage Dashboard: https://console.cloud.google.com/storage
- [ ] Secret Manager Dashboard: https://console.cloud.google.com/security/secret-manager

### Update Application
To deploy a new version:
1. Build and push new Docker image with a new tag
2. Update `image_uri` in `terraform.tfvars`
3. Run `terraform apply`

## 🧹 Cleanup (if needed)

### Destroy All Resources
```bash
terraform destroy
```
- [ ] Type `yes` to confirm
- [ ] All resources deleted

**Note**: Secrets in Secret Manager will NOT be deleted. Delete them manually if needed:
```bash
gcloud secrets delete mongodb-uri --project=properties-app-418208
gcloud secrets delete gmail-username --project=properties-app-418208
gcloud secrets delete gmail-password --project=properties-app-418208
```

## 📝 Notes

- Estimated deployment time: 5-10 minutes
- First-time setup may take longer due to API enablement
- Keep your `terraform.tfstate` file safe (contains infrastructure state)
- Consider using Terraform Cloud or GCS backend for state management in production

---

**Date**: _______________
**Deployed by**: _______________
**Service URL**: _______________
