#!/bin/bash

# Script to add secret values to GCP Secret Manager
# Run this AFTER terraform apply creates the secrets

PROJECT_ID="properties-app-418208"

echo "================================================"
echo "Adding Secret Values to GCP Secret Manager"
echo "================================================"
echo ""
echo "This script will help you add values to the secrets created by Terraform."
echo "You'll be prompted to enter each secret value."
echo ""

# Function to add secret version
add_secret_version() {
    local secret_name=$1
    local prompt_text=$2
    
    echo "-------------------------------------------"
    echo "Adding value for: $secret_name"
    echo "$prompt_text"
    echo "-------------------------------------------"
    
    # Read secret value (hidden input)
    read -sp "Enter value: " secret_value
    echo ""
    
    if [ -z "$secret_value" ]; then
        echo "❌ No value provided. Skipping $secret_name"
        return 1
    fi
    
    # Add secret version
    echo "$secret_value" | gcloud secrets versions add "$secret_name" \
        --project="$PROJECT_ID" \
        --data-file=-
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully added value to $secret_name"
    else
        echo "❌ Failed to add value to $secret_name"
        return 1
    fi
    
    echo ""
}

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is not installed"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo "❌ Error: Not authenticated with gcloud"
    echo "Please run: gcloud auth login"
    exit 1
fi

# Set project
echo "Setting project to: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"
echo ""

# Add MongoDB URI
add_secret_version "mongodb-uri" "Enter your MongoDB connection string (e.g., mongodb+srv://user:pass@cluster.mongodb.net/db)"

# Add Gmail Username
add_secret_version "gmail-username" "Enter your Gmail email address (e.g., yourname@gmail.com)"

# Add Gmail Password
add_secret_version "gmail-password" "Enter your Gmail App Password (16 characters, no spaces)"

echo "================================================"
echo "✅ Secret values setup complete!"
echo "================================================"
echo ""
echo "To verify secrets were added, run:"
echo "  gcloud secrets versions list mongodb-uri --project=$PROJECT_ID"
echo "  gcloud secrets versions list gmail-username --project=$PROJECT_ID"
echo "  gcloud secrets versions list gmail-password --project=$PROJECT_ID"
echo ""
echo "Now you can run: terraform apply"
echo "to deploy your Cloud Run service with the secrets."
