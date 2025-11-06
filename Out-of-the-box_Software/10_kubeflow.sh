# =====================================================
# environmental variables for central-env.common
# =====================================================
source ../Environmental_Variables/.env.common

echo "##############################################################"
echo "Set NFS server for kubeflow:"
echo ""
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
--create-namespace \
--namespace nfs-provisioner \
--set nfs.server=${CENTRAL_STORAGE_IP} \
--set nfs.path=${NFS_SERVER_PATH}

# [Optional] if you need to change above setting
# helm upgrade nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
#   --namespace nfs-provisioner \
#   --set nfs.server=${CENTRAL_STORAGE_IP} \ # This is storage service ip
#   --set nfs.path=${NFS_SERVER_PATH} # This is the route of nfs server path
echo "##############################################################"

echo ""
echo "##############################################################"
echo "Build kubeflow :"
echo ""
# Download kubeflow and kustomize
git clone https://github.com/kubeflow/manifests.git
cd manifests
git checkout v1.9.0
wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.2.1/kustomize_v5.2.1_linux_amd64.tar.gz

# Unzip kustomize and Configure kustomize
tar -xzvf kustomize_v5.2.1_linux_amd64.tar.gz
chmod 777 kustomize
mv kustomize /usr/bin/kustomize

# set nfs-client for kubeflow storageclass
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# build kubeflow
cd manifests
while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Deny kubeflow cache :"
echo ""
export NAMESPACE=kubeflow
sudo kubectl get mutatingwebhookconfiguration cache-webhook-${NAMESPACE}
sudo kubectl patch mutatingwebhookconfiguration cache-webhook-${NAMESPACE} --type='json' -p='[{"op":"replace", "path": "/webhooks/0/rules/0/operations/0", "value": "DELETE"}]'

echo "##############################################################"
