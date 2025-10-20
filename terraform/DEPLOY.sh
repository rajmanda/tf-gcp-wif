#!/bin/bash

# Deploy Kalyanam Frontend to Cloud Run
# This script automates the deployment process

set -e  # Exit on error

echo "========================================"
echo "Kalyanam Frontend - Cloud Run Deployment"
echo "========================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "ℹ $1"
}

# Check prerequisites
echo "Checking prerequisites..."
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI not found. Please install it first."
    exit 1
fi
print_success "gcloud CLI found"

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform not found. Please install it first."
    exit 1
fi
print_success "Terraform found ($(terraform version | head -n1))"

# Check if authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    print_error "Not authenticated with gcloud. Run: gcloud auth login"
    exit 1
fi
ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1)
print_success "Authenticated as: $ACTIVE_ACCOUNT"

# Get current project
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ -z "$CURRENT_PROJECT" ]; then
    print_error "No GCP project set. Run: gcloud config set project PROJECT_ID"
    exit 1
fi
print_success "Project: $CURRENT_PROJECT"

echo ""
print_info "All prerequisites met!"
echo ""

# Confirm deployment
echo "========================================"
echo "Ready to deploy Kalyanam Frontend"
echo "========================================"
echo "Project: $CURRENT_PROJECT"
echo "Account: $ACTIVE_ACCOUNT"
echo ""
read -p "Continue with deployment? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_warning "Deployment cancelled."
    exit 0
fi

echo ""
echo "Starting deployment..."
echo ""

# Initialize Terraform
print_info "Step 1/3: Initializing Terraform..."
if terraform init; then
    print_success "Terraform initialized"
else
    print_error "Terraform initialization failed"
    exit 1
fi

echo ""

# Plan deployment
print_info "Step 2/3: Planning deployment..."
if terraform plan -out=tfplan; then
    print_success "Terraform plan created"
else
    print_error "Terraform plan failed"
    exit 1
fi

echo ""
print_warning "Please review the plan above."
read -p "Apply this plan? (yes/no): " APPLY_CONFIRM

if [ "$APPLY_CONFIRM" != "yes" ]; then
    print_warning "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

echo ""

# Apply deployment
print_info "Step 3/3: Applying deployment..."
if terraform apply tfplan; then
    print_success "Deployment successful!"
else
    print_error "Deployment failed"
    rm -f tfplan
    exit 1
fi

# Clean up plan file
rm -f tfplan

echo ""
echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo ""

# Get outputs
SERVICE_URL=$(terraform output -raw service_url 2>/dev/null)
SERVICE_NAME=$(terraform output -raw service_name 2>/dev/null)
REGION=$(terraform output -raw region 2>/dev/null)

echo "Service Details:"
echo "  Name: $SERVICE_NAME"
echo "  Region: $REGION"
echo "  URL: $SERVICE_URL"
echo ""

print_success "Your application is now live!"
echo ""
print_info "Next steps:"
echo "  1. Test the service: curl -I $SERVICE_URL"
echo "  2. Open in browser: $SERVICE_URL"
echo "  3. View logs: gcloud run services logs read $SERVICE_NAME --region=$REGION"
echo ""
