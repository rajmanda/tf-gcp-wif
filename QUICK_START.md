# Quick Start Deployment Guide

## ⚡ Fast Track to Deployment

Follow these steps to deploy your RSVP backend to GCP Cloud Run.

## Prerequisites

1. **GCP Authentication**
   ```bash
   gcloud auth login
   gcloud config set project properties-app-418208
   ```

2. **Terraform Installed**
   ```bash
   terraform --version  # Should be >= 1.0
   ```

## Step-by-Step Deployment

### Step 1: Initialize Terraform
```bash
cd /app
terraform init
```

Expected output: `Terraform has been successfully initialized!`

---

### Step 2: Apply Terraform (Create Secrets)
```bash
terraform apply -target=google_secret_manager_secret.mongodb_uri \
                -target=google_secret_manager_secret.gmail_username \
                -target=google_secret_manager_secret.gmail_password
```

This creates the empty secret containers. Type `yes` when prompted.

---

### Step 3: Add Secret Values

**Option A: Using the helper script (Recommended)**
```bash
./add-secret-values.sh
```

The script will prompt you to enter:
- MongoDB connection string
- Gmail email address
- Gmail app password

**Option B: Manual method**
```bash
# Add MongoDB URI
echo -n "mongodb+srv://user:password@cluster.mongodb.net/dbname" | \
  gcloud secrets versions add mongodb-uri --data-file=- --project=properties-app-418208

# Add Gmail username
echo -n "your-email@gmail.com" | \
  gcloud secrets versions add gmail-username --data-file=- --project=properties-app-418208

# Add Gmail app password (get from Google Account settings)
echo -n "your-16-char-app-password" | \
  gcloud secrets versions add gmail-password --data-file=- --project=properties-app-418208
```

**Verify secrets have values:**
```bash
gcloud secrets versions list mongodb-uri --project=properties-app-418208
gcloud secrets versions list gmail-username --project=properties-app-418208
gcloud secrets versions list gmail-password --project=properties-app-418208

gcloud secrets versions access latest --secret=mongodb-uri
gcloud secrets versions access latest --secret=gmail-username
gcloud secrets versions access latest --secret=gmail-password
```

You should see version 1 in "ENABLED" state for each.

---

### Step 4: Deploy Everything
```bash
terraform apply
```

Review the plan carefully. You should see:
- ✅ 3 secrets already created
- ✅ APIs being enabled
- ✅ Service account being created
- ✅ IAM permissions being granted
- ✅ GCS bucket being created
- ✅ Cloud Run service being deployed

Type `yes` to proceed.

---

### Step 5: Get Your Service URL
```bash
terraform output service_url
```

Copy this URL - it's your backend endpoint!

---

## Verification

### Test Health Endpoint
```bash
SERVICE_URL=$(terraform output -raw service_url)
curl $SERVICE_URL/actuator/health
```

Expected response:
```json
{"status":"UP"}
```

### View Logs
```bash
gcloud run services logs tail rsvp-backend --region=us-central1 --project=properties-app-418208
```

---

## Troubleshooting

### Error: "Secret ... not found"
**Solution**: The secrets were created but have no values. Run Step 3 again to add values.

### Error: "deletion_protection"
**Solution**: Already fixed! The config now includes `deletion_protection = false`.

### Error: "Permission denied"
**Solution**: 
```bash
# Grant yourself owner role
gcloud projects add-iam-policy-binding properties-app-418208 \
  --member="user:$(gcloud config get-value account)" \
  --role="roles/owner"
```

### Service Not Starting
**Solution**: Check logs for errors:
```bash
gcloud run services logs read rsvp-backend --region=us-central1 --limit=50
```

Common issues:
- MongoDB connection string incorrect
- Docker image not accessible
- Application not listening on port 8080
- Missing `/actuator/health` endpoint

---

## What Gets Deployed?

| Resource | Name | Description |
|----------|------|-------------|
| Cloud Run Service | `rsvp-backend` | Your Spring Boot application |
| GCS Bucket | `kalyanam_bucket` | File storage |
| Service Account | `rsvp-backend-sa` | For service permissions |
| Secrets | `mongodb-uri`, `gmail-username`, `gmail-password` | Secure credentials |

---

## Update Deployment

### Update Application Code
1. Build new Docker image with new tag
2. Update `image_uri` in `terraform.tfvars`
3. Run `terraform apply`

### Update Secret Values
```bash
# Update a secret
echo -n "new-value" | gcloud secrets versions add mongodb-uri --data-file=- --project=properties-app-418208
```

Cloud Run will automatically pick up the new version on next deployment.

### Update Frontend URLs
1. Edit `frontend_url` in `terraform.tfvars`
2. Run `terraform apply`

---

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

⚠️ **Warning**: This will delete:
- Cloud Run service
- GCS bucket and all files
- Service account
- IAM bindings

Secrets will remain in Secret Manager (delete manually if needed):
```bash
gcloud secrets delete mongodb-uri --project=properties-app-418208
gcloud secrets delete gmail-username --project=properties-app-418208
gcloud secrets delete gmail-password --project=properties-app-418208
```

---

## Need Help?

- 📖 Full documentation: See `README.md`
- ✅ Detailed checklist: See `DEPLOYMENT_CHECKLIST.md`
- 📝 What changed: See `CHANGES.md`
- 🔍 View logs: `gcloud run services logs tail rsvp-backend --region=us-central1`
- 💬 GCP Console: https://console.cloud.google.com/run

---

## Cost Estimate

**Monthly costs (approximate):**
- Cloud Run: $5-50 (depends on traffic)
- GCS Storage: $0.02/GB
- Secret Manager: ~$0.20
- **Total**: ~$10-100/month

Free tier includes:
- 2 million requests/month
- 360,000 GB-seconds of compute
- First 6 secret versions free

---

## Next Steps After Deployment

1. ✅ Update your frontend to use the new `service_url`
2. ✅ Test all API endpoints
3. ✅ Verify CORS is working
4. ✅ Test file uploads to GCS
5. ✅ Set up monitoring/alerts in GCP Console
6. ✅ Configure custom domain (optional)
7. ✅ Set up CI/CD pipeline (optional)

**Your backend is now live and ready to serve traffic!** 🚀
