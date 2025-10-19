#!/bin/bash

# Script to fix the existing deployment errors
set -e

PROJECT_ID="properties-app-418208"
REGION="us-central1"
BUCKET_NAME="kalyanam_bucket"

echo "=========================================="
echo "🔧 Fixing Terraform State Issues"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "Step 1: Importing existing GCS bucket into Terraform state"
echo "-------------------------------------------"

# Check if bucket exists
if gsutil ls -b gs://$BUCKET_NAME &> /dev/null; then
    print_warning "Bucket $BUCKET_NAME already exists"
    
    # Check if it's in terraform state
    if terraform state show google_storage_bucket.shravani &> /dev/null; then
        print_success "Bucket already in Terraform state"
    else
        print_warning "Importing bucket into Terraform state..."
        terraform import google_storage_bucket.shravani $BUCKET_NAME
        if [ $? -eq 0 ]; then
            print_success "Bucket imported successfully"
        else
            print_error "Failed to import bucket"
            echo "You may need to manually import with:"
            echo "  terraform import google_storage_bucket.shravani $BUCKET_NAME"
        fi
    fi
else
    print_success "Bucket doesn't exist yet, will be created"
fi

echo ""
echo "Step 2: Updating Cloud Run service with deletion_protection=false"
echo "-------------------------------------------"

# Check if Cloud Run service exists
if gcloud run services describe rsvp-backend --region=$REGION --project=$PROJECT_ID &> /dev/null; then
    print_warning "Cloud Run service already exists"
    print_warning "Applying targeted update to add deletion_protection=false..."
    
    terraform apply -target=google_cloud_run_v2_service.rsvp_backend -auto-approve
    
    if [ $? -eq 0 ]; then
        print_success "Cloud Run service updated with deletion_protection=false"
    else
        print_error "Failed to update Cloud Run service"
        exit 1
    fi
else
    print_success "Cloud Run service doesn't exist yet, will be created"
fi

echo ""
echo "Step 3: Running full terraform apply"
echo "-------------------------------------------"

terraform apply

if [ $? -eq 0 ]; then
    print_success "Deployment completed successfully!"
else
    print_error "Deployment failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ All issues resolved!"
echo "=========================================="
