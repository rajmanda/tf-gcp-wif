# Kalyanam Frontend - GCP Cloud Run Deployment

This Terraform configuration deploys the Kalyanam Angular application to Google Cloud Run. The application is a containerized NGINX-served Angular SPA that provides a wedding RSVP management interface.

## Architecture Overview

- **Cloud Run Service**: Hosts the Angular application served by NGINX
- **Service Account**: Dedicated service account with minimal permissions for Cloud Run execution
- **Public Access**: Publicly accessible frontend application
- **Container**: Docker image hosted on Docker Hub (`dockerrajmanda/kalyanam`)

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
  - `roles/resourcemanager.projectIamAdmin`

### 3. Terraform Installation

Install Terraform (version >= 1.0):

```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### 4. Docker Image

The deployment uses the pre-built Docker image:

- **Image**: `docker.io/dockerrajmanda/kalyanam:405`
- **Registry**: Docker Hub (publicly accessible)
- **Build**: Multi-stage build with Node.js (Angular build) + NGINX (serving)

## Configuration

### Variables

All configurable variables are defined in `terraform.tfvars`:

```hcl
project_id   = "properties-app-418208"
region       = "us-central1"
service_name = "kalyanam-frontend"
image_uri    = "docker.io/dockerrajmanda/kalyanam:405"
```

### Variable Descriptions

- **project_id**: Your GCP project ID
- **region**: GCP region for deployment (default: us-central1)
- **service_name**: Name of the Cloud Run service (default: kalyanam-frontend)
- **image_uri**: Full container image URI including tag

## Deployment Steps

### 1. Clone the Repository

```bash
git clone https://github.com/rajmanda/tf-gcp-wif.git
cd tf-gcp-wif
git checkout feature/deploy-kalyanam-as-cloudrun
cd terraform
```

### 2. Initialize Terraform

```bash
terraform init
```

This will:
- Download the Google Cloud provider plugin
- Initialize the backend
- Prepare the working directory

### 3. Review the Plan

```bash
terraform plan
```

Review the planned changes carefully. You should see:
- 2 API enablements (Cloud Run, IAM)
- 1 service account
- 1 Cloud Run service
- 1 Cloud Run IAM policy (public access)

### 4. Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

**Deployment time**: Approximately 2-3 minutes

### 5. Verify Deployment

After successful deployment, Terraform will output:

```
service_url              = "https://kalyanam-frontend-xxxxxxxxxx-uc.a.run.app"
service_name             = "kalyanam-frontend"
service_account_email    = "kalyanam-frontend-sa@properties-app-418208.iam.gserviceaccount.com"
region                   = "us-central1"
```

### 6. Test the Deployment

```bash
# Get the service URL
SERVICE_URL=$(terraform output -raw service_url)

# Test the frontend
curl -I $SERVICE_URL

# Or open in browser
echo "Open this URL in your browser: $SERVICE_URL"
```

## Resource Details

### Cloud Run Service

- **Name**: `kalyanam-frontend`
- **Region**: `us-central1`
- **Port**: `80` (NGINX default)
- **Access**: Public (unauthenticated)
- **Resources**: 
  - CPU: 1 vCPU
  - Memory: 512Mi
- **Health Checks**: 
  - Startup probe: HTTP GET on `/` (port 80)
  - Liveness probe: HTTP GET on `/` (port 80)

### Service Account

- **Name**: `kalyanam-frontend-sa`
- **Permissions**: Minimal (Cloud Run execution only)
- **Purpose**: Run the Cloud Run service with least privilege

### Container Configuration

The Docker image is a multi-stage build:

**Stage 1: Build**
- Base: `node:18-alpine`
- Installs dependencies
- Builds Angular app with production configuration
- Output: Static files in `/dist/kalyanam/browser`

**Stage 2: Serve**
- Base: `nginx:alpine`
- Copies built Angular app to NGINX html directory
- Custom NGINX config for Angular routing (SPA)
- Exposes port 80

## Maintenance

### Update Docker Image

To deploy a new version:

1. Build and push new Docker image with a new tag:
   ```bash
   docker build -t dockerrajmanda/kalyanam:406 .
   docker push dockerrajmanda/kalyanam:406
   ```

2. Update `image_uri` in `terraform.tfvars`:
   ```hcl
   image_uri = "docker.io/dockerrajmanda/kalyanam:406"
   ```

3. Apply the change:
   ```bash
   terraform apply
   ```

Cloud Run will perform a rolling update with zero downtime.

### Scale Configuration

Cloud Run automatically scales based on traffic:

- **Min Instances**: 0 (scales to zero when no traffic)
- **Max Instances**: 100 (default)
- **Concurrency**: 80 requests per instance (default)

To modify scaling:

1. Edit `005-deploy-cloud-run.tf`
2. Add scaling configuration in the `template` block:
   ```hcl
   scaling {
     min_instance_count = 1  # Always keep 1 instance running
     max_instance_count = 10  # Limit to 10 instances
   }
   ```

### View Logs

```bash
# View recent logs
gcloud run services logs read kalyanam-frontend --region=us-central1 --limit=50

# Follow logs in real-time
gcloud run services logs tail kalyanam-frontend --region=us-central1

# View logs in GCP Console
gcloud run services describe kalyanam-frontend --region=us-central1 --format="value(status.url)"
```

### Custom Domain

To map a custom domain:

```bash
# Map domain
gcloud run domain-mappings create --service=kalyanam-frontend --domain=www.kalyanam.com --region=us-central1

# Verify domain ownership in GCP Console
# Add DNS records as instructed
```

## Troubleshooting

### Permission Denied Errors

**Error**: `Permission denied` or `403 Forbidden`

**Solution**: 
1. Verify your GCP account has required IAM roles
2. Run: `gcloud auth list` to check authenticated account
3. Re-authenticate: `gcloud auth login`

### Container Fails to Start

**Error**: Service fails health checks

**Solution**:
1. Verify Docker image exists and is accessible:
   ```bash
   docker pull docker.io/dockerrajmanda/kalyanam:405
   ```

2. Check Cloud Run logs:
   ```bash
   gcloud run services logs read kalyanam-frontend --region=us-central1
   ```

3. Verify NGINX is configured to listen on port 80
4. Test locally:
   ```bash
   docker run -p 8080:80 docker.io/dockerrajmanda/kalyanam:405
   curl http://localhost:8080
   ```

### Deployment Timeout

**Error**: Terraform apply times out

**Solution**:
1. Check API enablement status:
   ```bash
   gcloud services list --enabled --project=properties-app-418208
   ```

2. Manually enable Cloud Run API:
   ```bash
   gcloud services enable run.googleapis.com --project=properties-app-418208
   ```

3. Retry deployment

### Service Not Accessible

**Error**: Service URL returns 404 or connection refused

**Solution**:
1. Verify service is running:
   ```bash
   gcloud run services describe kalyanam-frontend --region=us-central1
   ```

2. Check IAM policy for public access:
   ```bash
   gcloud run services get-iam-policy kalyanam-frontend --region=us-central1
   ```

3. Verify `allUsers` has `roles/run.invoker` role

### NGINX 404 for Routes

**Error**: Angular routes return 404

**Solution**: 
- Verify `nginx.conf` has proper SPA routing configuration:
  ```nginx
  location / {
      root /usr/share/nginx/html/kalyanam;
      try_files $uri $uri/ /index.html;
  }
  ```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete:
- The Cloud Run service
- The service account
- All IAM bindings

Type `yes` to confirm deletion.

## Cost Estimation

Approximate monthly costs (as of 2025):

### Cloud Run Pricing
- **CPU**: $0.00002400 per vCPU-second
- **Memory**: $0.00000250 per GiB-second
- **Requests**: $0.40 per million requests
- **Free Tier**: 
  - 2 million requests per month
  - 360,000 vCPU-seconds per month
  - 180,000 GiB-seconds of memory per month

### Example Cost Scenarios

**Low Traffic** (10,000 requests/month, avg 100ms response time):
- Requests: Free (within free tier)
- CPU: Free (within free tier)
- Memory: Free (within free tier)
- **Total**: $0/month

**Medium Traffic** (500,000 requests/month, avg 200ms response time):
- Requests: Free (within free tier)
- CPU: ~$1-2/month
- Memory: ~$0.50-1/month
- **Total**: ~$2-3/month

**High Traffic** (5 million requests/month, avg 150ms response time):
- Requests: ~$1.20/month
- CPU: ~$8-12/month
- Memory: ~$3-5/month
- **Total**: ~$12-18/month

**Note**: Actual costs depend on:
- Traffic patterns
- Response times
- Image size
- Cold start frequency

## Security Considerations

1. **Public Access**: The Cloud Run service allows unauthenticated access (`allUsers`). This is appropriate for a public-facing frontend application.

2. **HTTPS**: Cloud Run automatically provides HTTPS endpoints with managed TLS certificates.

3. **Service Account**: Uses a dedicated service account with minimal permissions (no additional GCP service access).

4. **Container Security**: 
   - Uses official base images (Node.js, NGINX)
   - Multi-stage build reduces attack surface
   - No secrets or credentials in the container

5. **CORS**: If this frontend calls a backend API, ensure backend has proper CORS configuration.

## Differences from Kubernetes Deployment

### Removed Components
- **HorizontalPodAutoscaler**: Cloud Run has built-in autoscaling
- **Service**: Cloud Run provides automatic load balancing
- **Namespace**: Not applicable in Cloud Run
- **Service Account (GKE-specific)**: Replaced with Cloud Run service account

### Advantages of Cloud Run
1. **Serverless**: No cluster management required
2. **Scale to Zero**: Automatically scales to 0 when no traffic (cost savings)
3. **Automatic HTTPS**: Managed SSL certificates
4. **Simplified Deployment**: Single resource vs multiple K8s resources
5. **Pay Per Use**: Only pay for actual usage, not idle capacity

### Trade-offs
1. **Stateless Only**: No support for stateful workloads
2. **Request Timeout**: 60 minutes max (not an issue for frontend)
3. **No Direct Pod Access**: Limited debugging options compared to K8s

## Integration with Backend

If this frontend connects to the RSVP backend (also deployed on Cloud Run), update the Angular environment configuration:

```typescript
// src/environments/environment.prod.ts
export const environment = {
  production: true,
  apiUrl: 'https://rsvp-backend-xxxxxxxxxx-uc.a.run.app'
};
```

Rebuild the Docker image and redeploy after updating the API URL.

## Support

For issues or questions:

1. Check the [Troubleshooting](https://github.com/rajmanda/tf-gcp-wif/tree/feature/deploy-kalyanam-as-cloudrun#troubleshooting) section
2. Review Cloud Run logs: `gcloud run services logs read kalyanam-frontend --region=us-central1`
3. Verify all prerequisites are met
4. Check Terraform state: `terraform show`

## Version Information

- **Terraform**: >= 1.0
- **Google Provider**: >= 7.7.0
- **Cloud Run**: v2 API
- **Angular**: 19.2.0
- **Node.js**: 18-alpine (build)
- **NGINX**: alpine (runtime)

## Contributing

To make changes:

1. Create a new branch
2. Modify Terraform files
3. Test with `terraform plan`
4. Submit pull request

## License

This Terraform configuration is provided as-is for deployment of the Kalyanam application.

## References

- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Angular Deployment Guide](https://angular.io/guide/deployment)
- [NGINX Configuration](https://nginx.org/en/docs/)
