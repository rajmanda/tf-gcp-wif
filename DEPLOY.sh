#!/bin/bash

# Automated deployment script for RSVP Backend to GCP Cloud Run
# This script guides you through the entire deployment process

set -e  # Exit on error

PROJECT_ID="properties-app-418208"
REGION="us-central1"
SERVICE_NAME="rsvp-backend"

echo "=========================================="
echo "🚀 RSVP Backend Deployment Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "ℹ️  $1"
}

# Check prerequisites
echo "Step 0: Checking prerequisites..."
echo "-------------------------------------------"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi
print_success "gcloud CLI is installed"

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed"
    echo "Please install it from: https://www.terraform.io/downloads"
    exit 1
fi
print_success "Terraform is installed"

# Check authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    print_error "Not authenticated with gcloud"
    echo "Please run: gcloud auth login"
    exit 1
fi
ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -n1)
print_success "Authenticated as: $ACCOUNT"

# Set project
echo ""
print_info "Setting GCP project to: $PROJECT_ID"
gcloud config set project "$PROJECT_ID" > /dev/null 2>&1
print_success "Project set"

echo ""
echo "=========================================="
echo "Step 1: Initialize Terraform"
echo "=========================================="
terraform init
if [ $? -eq 0 ]; then
    print_success "Terraform initialized"
else
    print_error "Terraform initialization failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "Step 2: Create Secret Containers"
echo "=========================================="
print_info "Creating empty secrets in Secret Manager..."
terraform apply -auto-approve \
    -target=google_secret_manager_secret.mongodb_uri \
    -target=google_secret_manager_secret.gmail_username \
    -target=google_secret_manager_secret.gmail_password

if [ $? -eq 0 ]; then
    print_success "Secret containers created"
else
    print_error "Failed to create secrets"
    exit 1
fi

echo ""
echo "=========================================="
echo "Step 3: Add Secret Values"
echo "=========================================="
print_warning "You need to add values to the secrets"
echo ""
echo "Choose an option:"
echo "  1. Use interactive script (recommended)"
echo "  2. Add manually later"
echo ""
read -p "Enter choice (1 or 2): " choice

if [ "$choice" == "1" ]; then
    if [ -f "./add-secret-values.sh" ]; then
        ./add-secret-values.sh
    else
        print_error "add-secret-values.sh not found"
        print_info "Please add secrets manually using:"
        echo "  gcloud secrets versions add mongodb-uri --data-file=-"
        echo "  gcloud secrets versions add gmail-username --data-file=-"
        echo "  gcloud secrets versions add gmail-password --data-file=-"
        exit 1
    fi
else
    print_warning "Skipping secret value addition"
    print_info "Remember to add secret values before deploying:"
    echo ""
    echo "  echo -n 'your-mongodb-uri' | gcloud secrets versions add mongodb-uri --data-file=-"
    echo "  echo -n 'your-email@gmail.com' | gcloud secrets versions add gmail-username --data-file=-"
    echo "  echo -n 'your-app-password' | gcloud secrets versions add gmail-password --data-file=-"
    echo ""
    read -p "Press Enter to continue when secrets are added..."
fi

echo ""
echo "=========================================="
echo "Step 4: Verify Secrets Have Values"
echo "=========================================="
print_info "Checking if secrets have values..."

for secret in "mongodb-uri" "gmail-username" "gmail-password"; do
    versions=$(gcloud secrets versions list "$secret" --filter="state:ENABLED" --format="value(name)" --project="$PROJECT_ID" 2>/dev/null | wc -l)
    if [ "$versions" -gt 0 ]; then
        print_success "Secret '$secret' has value (version $versions)"
    else
        print_error "Secret '$secret' has no value!"
        echo "Please add a value using:"
        echo "  echo -n 'your-value' | gcloud secrets versions add $secret --data-file=- --project=$PROJECT_ID"
        exit 1
    fi
done

echo ""
echo "=========================================="
echo "Step 5: Deploy Full Infrastructure"
echo "=========================================="
print_info "This will create:"
echo "  - Cloud Run service (rsvp-backend)"
echo "  - GCS bucket (kalyanam_bucket)"
echo "  - Service account and IAM permissions"
echo "  - API enablements"
echo ""
read -p "Continue with deployment? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    print_warning "Deployment cancelled"
    exit 0
fi

terraform apply

if [ $? -eq 0 ]; then
    print_success "Deployment successful!"
else
    print_error "Deployment failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "Step 6: Deployment Summary"
echo "=========================================="

# Get outputs
SERVICE_URL=$(terraform output -raw service_url 2>/dev/null)
BUCKET_NAME=$(terraform output -raw gcs_bucket_name 2>/dev/null)
SA_EMAIL=$(terraform output -raw service_account_email 2>/dev/null)

echo ""
print_success "Deployment Complete!"
echo ""
echo "📋 Resource Details:"
echo "  Service URL: $SERVICE_URL"
echo "  Bucket Name: $BUCKET_NAME"
echo "  Service Account: $SA_EMAIL"
echo ""

echo "=========================================="
echo "Step 7: Verify Deployment"
echo "=========================================="
print_info "Testing health endpoint..."

sleep 5  # Give service a moment to stabilize

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/actuator/health" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" == "200" ]; then
    print_success "Health check passed! Service is running."
else
    print_warning "Health check returned HTTP $HTTP_CODE"
    print_info "The service may still be starting up. Check logs with:"
    echo "  gcloud run services logs tail $SERVICE_NAME --region=$REGION"
fi

echo ""
echo "=========================================="
echo "🎉 Deployment Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "  1. Test your API: curl $SERVICE_URL/actuator/health"
echo "  2. View logs: gcloud run services logs tail $SERVICE_NAME --region=$REGION"
echo "  3. Update frontend with backend URL: $SERVICE_URL"
echo "  4. Monitor: https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME"
echo ""
print_success "Your RSVP backend is live! 🚀"
