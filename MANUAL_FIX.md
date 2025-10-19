# Manual Fix for Current Errors

## Errors You're Seeing

1. **Cloud Run deletion_protection error**: The service exists but needs to be updated
2. **Bucket conflict error**: The bucket `kalyanam_bucket` already exists

## Quick Fix (Choose One Method)

### Method 1: Automated Fix Script (Easiest)

```bash
./FIX_ERRORS.sh
```

This script will:
- Import the existing bucket
- Update Cloud Run with deletion_protection=false
- Complete the deployment

---

### Method 2: Manual Step-by-Step

#### Step 1: Import the Existing Bucket

```bash
terraform import google_storage_bucket.shravani kalyanam_bucket
```

Expected output: `Import successful!`

#### Step 2: Update Cloud Run Service Only

```bash
terraform apply -target=google_cloud_run_v2_service.rsvp_backend
```

This will update the existing Cloud Run service to have `deletion_protection=false`.
Type `yes` when prompted.

#### Step 3: Apply Full Configuration

```bash
terraform apply
```

Type `yes` when prompted.

---

### Method 3: Fresh Start (If Above Methods Don't Work)

If you want to start completely fresh:

#### Option A: Remove the bucket and recreate
```bash
# Delete the existing bucket (WARNING: This deletes all files!)
gsutil rm -r gs://kalyanam_bucket

# Then run terraform apply
terraform apply
```

#### Option B: Use a different bucket name
```bash
# Edit terraform.tfvars
nano terraform.tfvars

# Change this line:
# gcs_bucket_name = "kalyanam_bucket"
# To:
# gcs_bucket_name = "kalyanam_bucket_2025"

# Save and exit (Ctrl+X, Y, Enter)

# Then run terraform apply
terraform apply
```

---

## Understanding the Errors

### Error 1: Cloud Run Deletion Protection

**What happened:**
- The Cloud Run service was created in a previous run
- By default, it has `deletion_protection = true`
- Our updated config has `deletion_protection = false`
- Terraform can't change this without first applying the new setting

**Solution:**
Apply the targeted update first:
```bash
terraform apply -target=google_cloud_run_v2_service.rsvp_backend
```

### Error 2: Bucket Already Exists

**What happened:**
- A previous `terraform apply` created the bucket
- The bucket wasn't tracked in the Terraform state (possibly state was reset)
- Terraform tries to create it again, but GCS says it already exists

**Solution:**
Import it into Terraform state:
```bash
terraform import google_storage_bucket.shravani kalyanam_bucket
```

---

## Verification After Fix

### Check Terraform State

```bash
# List all resources in state
terraform state list

# Should include:
# - google_storage_bucket.shravani
# - google_cloud_run_v2_service.rsvp_backend
# - google_secret_manager_secret.mongodb_uri
# - google_secret_manager_secret.gmail_username
# - google_secret_manager_secret.gmail_password
# - And others...
```

### Verify Deployment

```bash
# Get service URL
SERVICE_URL=$(terraform output -raw service_url)

# Test health endpoint
curl $SERVICE_URL/actuator/health
```

Expected: `{"status":"UP"}` or similar

---

## If Nothing Works

### Nuclear Option: Reset Everything

⚠️ **WARNING**: This will delete ALL deployed resources!

```bash
# 1. Destroy everything (if possible)
terraform destroy -auto-approve

# 2. Delete the bucket manually
gsutil rm -r gs://kalyanam_bucket

# 3. Clean terraform state
rm -rf .terraform terraform.tfstate terraform.tfstate.backup

# 4. Start fresh
terraform init
terraform apply
```

---

## Recommended Solution

**Try in this order:**

1. ✅ **First try**: `./FIX_ERRORS.sh` (automated)
2. ✅ **If that fails**: Manual Method 2 (import + targeted apply)
3. ✅ **Last resort**: Fresh start with different bucket name

---

## Get Help

If you're still stuck, check:

```bash
# View current Terraform state
terraform state list

# View detailed resource info
terraform state show google_storage_bucket.shravani
terraform state show google_cloud_run_v2_service.rsvp_backend

# Check if bucket exists
gsutil ls -b gs://kalyanam_bucket

# Check if Cloud Run service exists
gcloud run services describe rsvp-backend --region=us-central1 --project=properties-app-418208
```

Share the output of these commands if you need further help.
