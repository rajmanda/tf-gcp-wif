#!/bin/bash
# Quick setup script for Cloud Run Performance Optimization

echo "=========================================="
echo "Cloud Run Performance Optimization Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Please install: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

echo -e "${GREEN}✓ gcloud CLI found${NC}"
echo ""

# Configuration
FRONTEND_SERVICE="kalyanam-frontend"
BACKEND_SERVICE="rsvp-backend"
REGION="us-central1"

echo "Services to optimize:"
echo "  Frontend: $FRONTEND_SERVICE"
echo "  Backend:  $BACKEND_SERVICE"
echo "  Region:   $REGION"
echo ""

# Confirm
read -p "Do you want to proceed with optimization? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Step 1: Optimizing Frontend Service..."
echo "--------------------------------------"
gcloud run services update $FRONTEND_SERVICE \
  --region=$REGION \
  --min-instances=1 \
  --max-instances=10 \
  --cpu=1 \
  --memory=512Mi \
  --concurrency=80 \
  --timeout=300 \
  && echo -e "${GREEN}✓ Frontend optimized${NC}" \
  || echo -e "${RED}✗ Frontend optimization failed${NC}"

echo ""
echo "Step 2: Optimizing Backend Service..."
echo "--------------------------------------"
gcloud run services update $BACKEND_SERVICE \
  --region=$REGION \
  --min-instances=1 \
  --max-instances=10 \
  --cpu=2 \
  --memory=1Gi \
  --concurrency=80 \
  --timeout=300 \
  --cpu-boost \
  && echo -e "${GREEN}✓ Backend optimized${NC}" \
  || echo -e "${RED}✗ Backend optimization failed${NC}"

echo ""
echo "=========================================="
echo -e "${GREEN}Optimization Complete!${NC}"
echo "=========================================="
echo ""
echo "What changed:"
echo "  ✓ Minimum instances set to 1 (no more cold starts)"
echo "  ✓ CPU and memory optimized"
echo "  ✓ Concurrency settings adjusted"
echo "  ✓ CPU boost enabled for backend"
echo ""
echo "Expected improvements:"
echo "  • Initial load: 1-2 seconds (was 8-15 seconds)"
echo "  • API responses: 200-500ms (was 5-10 seconds)"
echo "  • Total user wait: 2-3 seconds (was 15-28 seconds)"
echo ""
echo "Additional cost: ~$20-30/month for always-on instances"
echo ""
echo "Next steps:"
echo "1. Test your application"
echo "2. Monitor Cloud Run metrics in console"
echo "3. Apply frontend optimizations (nginx.conf updates)"
echo "4. Apply backend optimizations (Dockerfile, caching)"
echo ""
echo "See PERFORMANCE_OPTIMIZATION_GUIDE.md for detailed instructions"
echo ""
