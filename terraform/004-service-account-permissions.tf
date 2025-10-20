# Grant minimal permissions to the service account
# Cloud Run services typically need very few permissions if they don't access other GCP resources

# If the frontend needs to access any GCP services, add IAM bindings here
# For a static Angular app served by NGINX, no additional permissions are typically needed
