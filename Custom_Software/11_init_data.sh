#!/bin/bash

# =====================================================
# environmental variables for central-env.common
# =====================================================
source ../Environmental_Variables/.env.common

# =====================================================
# Restart kafka
# =====================================================
docker restart kafka-1 kafka-2 kafka-3
docker start kafka-1 kafka-2 kafka-3

# =====================================================
# Port forward for kubeflow
# =====================================================
echo "create dex-port-forward to use tmux"
tmux new-session -d -s dex-port-forward
tmux send-keys -t dex-port-forward "kubectl port-forward svc/istio-ingressgateway -n istio-system ${KUBEFLOW_PORT}:80 --address '0.0.0.0'" C-m

# =====================================================
# Clear all data in the database (including test organizations), 
# and add a test account, roles, organizations, and an API key.
# =====================================================
docker exec -it aiml_authenticate_middleware python manage.py generate_data

# =====================================================
# Generate minio bucket
# =====================================================
docker exec -it aiml_file_mgt python manage.py initial_minio_bucket

# =====================================================
# Wait for pod running
# =====================================================
kubectl wait --for=condition=ready pod --all --timeout=30m -n kubeflow
