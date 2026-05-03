# Run this locally BEFORE applying the Deployments.
# It creates the imagePullSecret in the k8s-dashboard namespace
# so Kubernetes can pull images from the OCI Container Registry.
#
# Usage:
#   bash create-registry-secret.sh
#
# Or apply manually:
#   kubectl create secret docker-registry oci-registry-secret \
#     --docker-server=gru.ocir.io \
#     --docker-username='<NAMESPACE>/<your_email>' \
#     --docker-password='<auth_token>' \
#     --docker-email='<your_email>' \
#     -n k8s-dashboard
