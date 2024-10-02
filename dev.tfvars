name                       = "kuberetes-cluster-01"
project                    = "properties-app-418208"
project_id                 = "properties-app-418208"
region                     = "us-central1"
zones                      = ["us-central1-a", "us-central1-b", "us-central1-f"]
network                    = "vpc-01"
subnetwork                 = "us-central1-01"
ip_range_pods              = "us-central1-01-gke-01-pods"
ip_range_services          = "us-central1-01-gke-01-services"
service_account            = "project-service-account@properties-app-418208.iam.gserviceaccount.com"

node_pools = [
  {
    name                        = "default-node-pool"
    machine_type                = "e2-medium"
    node_locations              = "us-central1-b,us-central1-c"
    min_count                   = 1
    max_count                   = 100
    local_ssd_count             = 0
    spot                        = false
    disk_size_gb                = 100
    disk_type                   = "pd-standard"
    image_type                  = "COS_CONTAINERD"
    enable_gcfs                 = false
    enable_gvnic                = false
    logging_variant             = "DEFAULT"
    auto_repair                 = true
    auto_upgrade                = true
    initial_node_count          = 80
    accelerator_count           = 1
    accelerator_type            = "nvidia-l4"
    gpu_driver_version          = "LATEST"
    gpu_sharing_strategy        = "TIME_SHARING"
    max_shared_clients_per_gpu  = 2
  },
]
