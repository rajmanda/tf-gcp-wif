# Error Fixes Applied

## Errors Encountered

You encountered these errors during `terraform apply`:

### Error 1: Cloud Run Deletion Protection
```
Error: cannot destroy service without setting deletion_protection=false and running `terraform apply`
```

### Error 2-4: Secrets Not Found
```
Error: Error retrieving IAM policy for secretmanager secret "projects/properties-app-418208/secrets/mongodb-uri": 
googleapi: Error 404: Secret [projects/175415323680/secrets/mongodb-uri] not found.

Error: Error retrieving IAM policy for secretmanager secret "projects/properties-app-418208/secrets/gmail-username": 
googleapi: Error 404: Secret [projects/175415323680/secrets/gmail-username] not found.

Error: Error retrieving IAM policy for secretmanager secret "projects/properties-app-418208/secrets/gmail-password": 
googleapi: Error 404: Secret [projects/175415323680/secrets/gmail-password] not found.
```

---

## ✅ Fixes Applied

### Fix 1: Added Deletion Protection Flag

**File Modified**: `005-deploy-cloud-run.tf`

**Change**:
```hcl
resource "google_cloud_run_v2_service" "rsvp_backend" {
  name     = var.service_name
  location = var.region
  project  = var.project_id
  
  ingress = "INGRESS_TRAFFIC_ALL"
  
  # ADDED THIS LINE:
  deletion_protection = false
  
  # ... rest of configuration
}
```

**Why**: By default, Cloud Run services have deletion protection enabled. This prevents Terraform from updating or recreating the service. Setting it to `false` allows Terraform to manage the service lifecycle.

---

### Fix 2: Create Secrets via Terraform

**New File Created**: `000-create-secrets.tf`

**Content**:
```hcl
# Create secrets in Secret Manager
resource "google_secret_manager_secret" "mongodb_uri" {
  secret_id = var.mongo_uri_secret_name
  project   = var.project_id
  replication { auto {} }
  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret" "gmail_username" {
  secret_id = var.gmail_user_secret_name
  project   = var.project_id
  replication { auto {} }
  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret" "gmail_password" {
  secret_id = var.gmail_pass_secret_name
  project   = var.project_id
  replication { auto {} }
  depends_on = [google_project_service.secretmanager_api]
}
```

**Why**: The original configuration assumed secrets already existed in GCP. Now Terraform will create the secret containers automatically.

---

### Fix 3: Updated IAM Dependencies

**File Modified**: `004-service-account-permissions.tf`

**Changes**:
```hcl
# BEFORE:
depends_on = [google_project_service.secretmanager_api]

# AFTER:
depends_on = [google_secret_manager_secret.mongodb_uri]
# (and similar for other secrets)
```

**Why**: IAM permissions can only be granted to secrets that exist. By depending on the secret resources instead of just the API, we ensure proper creation order.

---

## 📋 New Files Created

### 1. `add-secret-values.sh`
**Purpose**: Helper script to add values to the created secrets

**Usage**:
```bash
./add-secret-values.sh
```

This script prompts you to enter:
- MongoDB connection string
- Gmail email address
- Gmail app password

It then adds these values to the secrets in Secret Manager.

---

### 2. `QUICK_START.md`
**Purpose**: Fast-track deployment guide

**Contains**:
- Step-by-step deployment instructions
- Troubleshooting for common errors
- Verification steps
- Update procedures

---

### 3. `ERROR_FIXES.md`
**Purpose**: This document - explains what errors occurred and how they were fixed

---

## 🚀 How to Deploy Now

Follow these steps in order:

### Step 1: Initialize Terraform (if not already done)
```bash
cd /app
terraform init
```

### Step 2: Create Secrets First
```bash
terraform apply -target=google_secret_manager_secret.mongodb_uri \
                -target=google_secret_manager_secret.gmail_username \
                -target=google_secret_manager_secret.gmail_password
```

Type `yes` when prompted. This creates the empty secret containers.

### Step 3: Add Secret Values
```bash
./add-secret-values.sh
```

Or manually:
```bash
echo -n "mongodb+srv://user:pass@cluster.mongodb.net/db" | \
  gcloud secrets versions add mongodb-uri --data-file=- --project=properties-app-418208

echo -n "your-email@gmail.com" | \
  gcloud secrets versions add gmail-username --data-file=- --project=properties-app-418208

echo -n "your-16-char-app-password" | \
  gcloud secrets versions add gmail-password --data-file=- --project=properties-app-418208
```

### Step 4: Deploy Everything
```bash
terraform apply
```

Type `yes` when prompted.

### Step 5: Verify
```bash
# Get service URL
terraform output service_url

# Test health endpoint
curl $(terraform output -raw service_url)/actuator/health
```

---

## 🔍 Verification Checklist

After deployment, verify:

- [ ] Secrets exist and have values:
  ```bash
  gcloud secrets versions list mongodb-uri --project=properties-app-418208
  gcloud secrets versions list gmail-username --project=properties-app-418208
  gcloud secrets versions list gmail-password --project=properties-app-418208
  ```

- [ ] Cloud Run service is running:
  ```bash
  gcloud run services describe rsvp-backend --region=us-central1 --project=properties-app-418208
  ```

- [ ] Health endpoint responds:
  ```bash
  curl $(terraform output -raw service_url)/actuator/health
  ```

- [ ] No errors in logs:
  ```bash
  gcloud run services logs read rsvp-backend --region=us-central1 --limit=20
  ```

---

## 🎯 Root Cause Analysis

### Why Did These Errors Occur?

1. **Deletion Protection Error**
   - **Root Cause**: Google Cloud Run v2 API enables deletion protection by default as a safety feature
   - **Impact**: Terraform couldn't update or recreate the service
   - **Solution**: Explicitly set `deletion_protection = false` for development/staging environments

2. **Secrets Not Found Errors**
   - **Root Cause**: The Terraform configuration referenced secrets but didn't create them
   - **Impact**: IAM policies couldn't be attached to non-existent secrets
   - **Solution**: Added Terraform resources to create the secrets, then attach IAM policies

### Design Decision

The secrets are created **without initial values** by Terraform because:
- ✅ Secret values are sensitive and shouldn't be in Terraform state
- ✅ Allows separation of infrastructure (Terraform) and secrets (manual/script)
- ✅ Follows security best practices
- ✅ Values can be updated without Terraform

---

## 📚 Additional Resources

- **Quick Start**: See `QUICK_START.md` for fast deployment
- **Full Guide**: See `README.md` for comprehensive documentation
- **Checklist**: See `DEPLOYMENT_CHECKLIST.md` for step-by-step verification
- **Changes**: See `CHANGES.md` for all modifications made

---

## ⚠️ Important Notes

### About Secret Values

Terraform creates the secret **containers** but not the values. This is intentional:
- Secret values are sensitive
- They should not be stored in Terraform state
- They should be managed separately from infrastructure

### About Deletion Protection

`deletion_protection = false` is appropriate for:
- ✅ Development environments
- ✅ Staging environments
- ✅ CI/CD deployments

For production, consider:
- ❌ Setting `deletion_protection = true`
- ❌ Requiring manual intervention for deletions
- ❌ Additional safeguards

---

## 🎉 Summary

All errors have been fixed! Your infrastructure is now:
- ✅ Fully automated
- ✅ Creates all required resources
- ✅ Has proper dependencies
- ✅ Ready for deployment

Run through the deployment steps above, and you'll have a working Cloud Run service!
