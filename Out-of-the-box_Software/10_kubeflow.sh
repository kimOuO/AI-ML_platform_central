# # =====================================================
# # environmental variables for central-env.common
# # =====================================================
# source ../Environmental_Variables/.env.common

# echo "##############################################################"
# echo "Set NFS server for kubeflow:"
# echo ""
# helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

# helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
# --create-namespace \
# --namespace nfs-provisioner \
# --set nfs.server=${CENTRAL_STORAGE_IP} \
# --set nfs.path=${NFS_SERVER_PATH}

# # [Optional] if you need to change above setting
# # helm upgrade nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
# #   --namespace nfs-provisioner \
# #   --set nfs.server=${CENTRAL_STORAGE_IP} \ # This is storage service ip
# #   --set nfs.path=${NFS_SERVER_PATH} # This is the route of nfs server path
# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Build kubeflow :"
# echo ""
# # Download kubeflow and kustomize
# git clone https://github.com/kubeflow/manifests.git
# cd manifests
# git checkout v1.9.0
# wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.2.1/kustomize_v5.2.1_linux_amd64.tar.gz

# # Unzip kustomize and Configure kustomize
# tar -xzvf kustomize_v5.2.1_linux_amd64.tar.gz
# chmod 777 kustomize
# mv kustomize /usr/bin/kustomize

# # set nfs-client for kubeflow storageclass
# kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# # build kubeflow
# cd manifests
# while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Deny kubeflow cache :"
# echo ""
# export NAMESPACE=kubeflow
# sudo kubectl get mutatingwebhookconfiguration cache-webhook-${NAMESPACE}
# sudo kubectl patch mutatingwebhookconfiguration cache-webhook-${NAMESPACE} --type='json' -p='[{"op":"replace", "path": "/webhooks/0/rules/0/operations/0", "value": "DELETE"}]'

# echo "##############################################################"
# # =====================================================
# # environmental variables for central-env.common
# # =====================================================
# source ../Environmental_Variables/.env.common

# echo "##############################################################"
# echo "Set NFS server for kubeflow:"
# echo ""
# helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

# helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
# --create-namespace \
# --namespace nfs-provisioner \
# --set nfs.server=${CENTRAL_STORAGE_IP} \
# --set nfs.path=${NFS_SERVER_PATH}

# # [Optional] if you need to change above setting
# # helm upgrade nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
# #   --namespace nfs-provisioner \
# #   --set nfs.server=${CENTRAL_STORAGE_IP} \ # This is storage service ip
# #   --set nfs.path=${NFS_SERVER_PATH} # This is the route of nfs server path
# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Build kubeflow :"
# echo ""
# # Download kubeflow and kustomize
# git clone https://github.com/kubeflow/manifests.git
# cd manifests
# git checkout v1.10-branch
# wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.2.1/kustomize_v5.2.1_linux_amd64.tar.gz

# # Unzip kustomize and Configure kustomize
# tar -xzvf kustomize_v5.2.1_linux_amd64.tar.gz
# chmod 777 kustomize
# mv kustomize /usr/bin/kustomize

# # set nfs-client for kubeflow storageclass
# kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# # build kubeflow
# cd manifests
# while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Deny kubeflow cache :"
# echo ""
# export NAMESPACE=kubeflow
# sudo kubectl get mutatingwebhookconfiguration cache-webhook-${NAMESPACE}
# sudo kubectl patch mutatingwebhookconfiguration cache-webhook-${NAMESPACE} --type='json' -p='[{"op":"replace", "path": "/webhooks/0/rules/0/operations/0", "value": "DELETE"}]'

# echo "##############################################################"

#!/bin/bash

# =====================================================
# environmental variables for central-env.common
# （如果後面都不再用到 .env 裡的內容，其實可以拿掉這行）
# =====================================================
# set -o errexit
# set -o nounset
# set -o pipefail
source ../Environmental_Variables/.env.common

echo "##############################################################"
echo "Set NFS server for kubeflow:"
echo ""
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

# 這裡改成「寫死」的 IP + 路徑
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
--create-namespace \
--namespace nfs-provisioner \
--set nfs.server=${CENTRAL_STORAGE_IP} \
--set nfs.path=${NFS_SERVER_PATH}

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Build kubeflow :"
echo ""
# Download kubeflow and kustomize
git clone https://github.com/kubeflow/manifests.git
cd manifests
git checkout v1.10-branch
wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.2.1/kustomize_v5.2.1_linux_amd64.tar.gz

# Unzip kustomize and Configure kustomize
tar -xzvf kustomize_v5.2.1_linux_amd64.tar.gz
chmod 777 kustomize
mv kustomize /usr/bin/kustomize

# ------------------------------------------------------------
# 2.5 先建立 kubeflow namespace（避免後面一堆 namespaces "kubeflow" not found）
# ------------------------------------------------------------
echo "============================================================"
echo "[2.5] 建立 kubeflow namespace"
echo "============================================================"

kubectl create namespace kubeflow --dry-run=client -o yaml | kubectl apply -f -

# ------------------------------------------------------------
# 3. 安裝 cert-manager
# ------------------------------------------------------------
echo "============================================================"
echo "[3] 安裝 cert-manager"
echo "============================================================"

# 1) 先安裝 cert-manager 本體
kustomize build common/cert-manager/base | kubectl apply -f -

# 2) 等 deployment Ready（含 webhook）
kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager
kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager-webhook
kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager-cainjector

# 3) 再安裝 Kubeflow issuer（這時 webhook 已經 ready）
kustomize build common/cert-manager/kubeflow-issuer/base | kubectl apply -f -

# ------------------------------------------------------------
# 4. 安裝 Istio (Kubeflow 預設設定)
# ------------------------------------------------------------
echo "============================================================"
echo "[4] 安裝 Istio (Kubeflow 預設設定)"
echo "============================================================"

# Istio CRDs
kustomize build common/istio/istio-crds/base | kubectl apply -f -
# Istio namespace + 基本設定
kustomize build common/istio/istio-namespace/base | kubectl apply -f -
# Istio 安裝（使用 oauth2-proxy overlay）
kustomize build common/istio/istio-install/overlays/oauth2-proxy | kubectl apply -f -

kubectl wait --for=condition=Available --timeout=600s -n istio-system deployment/istiod
kubectl wait --for=condition=Available --timeout=600s -n istio-system deployment/istio-ingressgateway

# ------------------------------------------------------------
# 5. OAuth2-proxy + Dex（登入機制）
# ------------------------------------------------------------
echo "============================================================"
echo "[5] OAuth2-proxy + Dex（登入機制）"
echo "============================================================"

# OAuth2-proxy
kustomize build common/oauth2-proxy/overlays/m2m-dex-only/ | kubectl apply -f -
kubectl wait --for=condition=Available --timeout=300s -n oauth2-proxy deployment/oauth2-proxy

# Dex（預設帳密：user@example.com / 12341234）
kustomize build common/dex/overlays/oauth2-proxy | kubectl apply -f -
kubectl wait --for=condition=Available --timeout=300s -n auth deployment/dex

# ------------------------------------------------------------
# 6. NetworkPolicy + RBAC + Kubeflow 的 Istio 資源 + Pipelines Core
# ------------------------------------------------------------
echo "============================================================"
echo "[6] NetworkPolicy + RBAC + Kubeflow 的 Istio 資源 + Pipelines"
echo "============================================================"

# NetworkPolicy
kustomize build common/networkpolicies/base | kubectl apply -f -

# Kubeflow Roles (ClusterRoles / ClusterRoleBindings 等)
kustomize build common/kubeflow-roles/base | kubectl apply -f -

# Kubeflow Istio 資源（VirtualService / Gateway 等）
kustomize build common/istio/kubeflow-istio-resources/base | kubectl apply -f -

# Kubeflow Pipelines (multi-user, cert-manager 版本)
# 部分環境會跳 DecoratorController / namespace 等警告，但不影響後續，可忽略
set +o errexit
kustomize build applications/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user | kubectl apply -f - || \
  echo "[WARN] Some Pipeline resources may have failed on first apply (e.g. DecoratorController). You can re-run this kustomize later if needed."
set -o errexit

# 先等 ml-pipeline-ui 起來（如果還沒建成功會 timeout，但腳本會照規則等）
kubectl wait --for=condition=Available --timeout=600s -n kubeflow deployment/ml-pipeline-ui || \
  echo "[WARN] ml-pipeline-ui not Ready yet. Please check later with: kubectl get pods -n kubeflow"

# ------------------------------------------------------------
# 6.1 關閉 Kubeflow Pipelines 的 cache webhook（cache-webhook-kubeflow）
# ------------------------------------------------------------
echo "============================================================"
echo "[6.1] 關閉 Kubeflow Pipelines 的 cache webhook（cache-webhook-kubeflow）"
echo "============================================================"

CACHE_WEBHOOK_NAME="cache-webhook-kubeflow"
if kubectl get mutatingwebhookconfiguration "${CACHE_WEBHOOK_NAME}" &>/dev/null; then
  echo "[INFO] Found mutatingwebhookconfiguration ${CACHE_WEBHOOK_NAME}, patching to only allow DELETE..."
  kubectl patch mutatingwebhookconfiguration "${CACHE_WEBHOOK_NAME}" \
    --type='json' \
    -p='[{"op":"replace", "path": "/webhooks/0/rules/0/operations/0", "value": "DELETE"}]'
  echo "[INFO] cache-webhook-kubeflow patched successfully."
else
  echo "[WARN] mutatingwebhookconfiguration ${CACHE_WEBHOOK_NAME} not found, skip cache webhook patch."
fi

# ------------------------------------------------------------
# 6.2 關閉 Kubeflow Pipelines 相關 DestinationRule 的 mTLS（TLS → DISABLE）
# ------------------------------------------------------------
echo "============================================================"
echo "[6.2] Patch Kubeflow Pipelines DestinationRule TLS = DISABLE"
echo "============================================================"

DEST_RULES=(
  ml-pipeline
  ml-pipeline-ui
  ml-pipeline-visualizationserver
  metadata-grpc-service
  ml-pipeline-minio
  ml-pipeline-mysql
)

for dr in "${DEST_RULES[@]}"; do
  if kubectl -n kubeflow get destinationrule "${dr}" &>/dev/null; then
    echo "  - Patching DestinationRule: ${dr}"
    kubectl -n kubeflow patch destinationrule "${dr}" \
      --type='json' \
      -p='[{"op":"replace","path":"/spec/trafficPolicy/tls","value":{"mode":"DISABLE"}}]'
  else
    echo "  - DestinationRule ${dr} not found, skip."
  fi
done

# （可選）重啟 Pipelines 相關 Pod，確保新流量都走正確設定
echo "[INFO] Restart Kubeflow Pipelines Pods to pick up new DestinationRule..."
kubectl -n kubeflow delete pod -l application-crd-id=kubeflow-pipelines --ignore-not-found

# ------------------------------------------------------------
# 7. 安裝 Central Dashboard
# ------------------------------------------------------------
echo "============================================================"
echo "[7] 安裝 Central Dashboard"
echo "============================================================"

kustomize build applications/centraldashboard/overlays/oauth2-proxy | kubectl apply -f -

kubectl wait --for=condition=Available --timeout=600s -n kubeflow deployment/centraldashboard || \
  echo "[WARN] centraldashboard not Ready yet. Please check: kubectl get pods -n kubeflow"

# ------------------------------------------------------------
# 8. Profiles + 預設使用者 (kubeflow-user-example-com)
# ------------------------------------------------------------
echo "============================================================"
echo "[8] Profiles + 預設使用者 (kubeflow-user-example-com)"
echo "============================================================"

# Profiles + KFAM（安裝 CRD / controller）
kustomize build applications/profiles/upstream/overlays/kubeflow | kubectl apply -f -

# 建立一個預設 Profile（user@example.com）
cat << 'EOF' | kubectl apply -f -
apiVersion: kubeflow.org/v1
kind: Profile
metadata:
  name: kubeflow-user-example-com
spec:
  owner:
    kind: User
    name: user@example.com
EOF

# ------------------------------------------------------------
# 9. Admission Webhook（Notebook 等資源需要）
# ------------------------------------------------------------
echo "============================================================"
echo "[9] Admission Webhook（Notebook 等資源需要）"
echo "============================================================"

kustomize build applications/admission-webhook/upstream/overlays/cert-manager | kubectl apply -f -

# ------------------------------------------------------------
# 10. Notebook / Volumes / PVC Viewer / Tensorboard
# ------------------------------------------------------------
echo "============================================================"
echo "[10] 安裝 Notebook / Volumes / PVC Viewer / Tensorboard (Web UI 相關)"
echo "============================================================"

# Notebook Controller
kustomize build applications/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -

# Jupyter Web App
kustomize build applications/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -

# Volumes Web App
kustomize build applications/volumes-web-app/upstream/overlays/istio | kubectl apply -f -

# PVC Viewer Controller
kustomize build applications/pvcviewer-controller/upstream/base | kubectl apply -f -

# Tensorboard Controller
kustomize build applications/tensorboard/tensorboard-controller/upstream/overlays/kubeflow | kubectl apply -f -

# Tensorboards Web App
kustomize build applications/tensorboard/tensorboards-web-app/upstream/overlays/istio | kubectl apply -f -


# echo "============================================================"
# echo "完成：Kubeflow 1.10.2 最小環境已套用（含 Pipelines cache webhook 關閉）。"
# echo "接下來建議檢查："
# echo "  - kubectl get pods -A"
# echo "  - kubectl get pods -n kubeflow"
# echo ""
# echo "若有少數 Pod CrashLoopBackOff，可把 log 貼給我，我們再一起 debug。"
# echo "============================================================"


# # set nfs-client for kubeflow storageclass
# kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# # build kubeflow
# cd manifests
# # while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
# echo "============================================================"
# echo "[2] 安裝 cert-manager"
# echo "============================================================"

# kustomize build common/cert-manager/base | kubectl apply -f -
# kustomize build common/cert-manager/kubeflow-issuer/base | kubectl apply -f -

# kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager
# kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager-webhook
# kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager-cainjector

# echo "============================================================"
# echo "[3] 安裝 Istio (Kubeflow 預設設定)"
# echo "============================================================"

# # Istio CRDs
# kustomize build common/istio/istio-crds/base | kubectl apply -f -
# # Istio namespace
# kustomize build common/istio/istio-namespace/base | kubectl apply -f -
# # Istio 安裝（使用 oauth2-proxy overlay）
# kustomize build common/istio/istio-install/overlays/oauth2-proxy | kubectl apply -f -

# kubectl wait --for=condition=Available --timeout=600s -n istio-system deployment/istiod
# kubectl wait --for=condition=Available --timeout=600s -n istio-system deployment/istio-ingressgateway

# echo "============================================================"
# echo "[4] OAuth2-proxy + Dex（登入機制）"
# echo "============================================================"

# # OAuth2-proxy
# kustomize build common/oauth2-proxy/overlays/m2m-dex-only/ | kubectl apply -f -
# kubectl wait --for=condition=Available --timeout=300s -n oauth2-proxy deployment/oauth2-proxy

# # Dex（預設帳密：user@example.com / 12341234）
# kustomize build common/dex/overlays/oauth2-proxy | kubectl apply -f -
# kubectl wait --for=condition=Available --timeout=300s -n auth deployment/dex

# echo "============================================================"
# echo "[5] NetworkPolicy + RBAC + Kubeflow 的 Istio 資源"
# echo "============================================================"

# kustomize build common/networkpolicies/base | kubectl apply -f -
# kustomize build common/kubeflow-roles/base | kubectl apply -f -
# kustomize build common/istio/kubeflow-istio-resources/base | kubectl apply -f -

# kustomize build applications/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user | kubectl apply -f -
# kubectl wait --for=condition=Available --timeout=600s -n kubeflow deployment/ml-pipeline-ui

# echo "============================================================"
# echo "[6.1] 關閉 Kubeflow Pipelines 的 cache webhook（cache-webhook-kubeflow）"
# echo "============================================================"

# # 有些環境 cache webhook 會干擾 PVC / volume 或造成奇怪錯誤
# # 我們檢查 mutatingwebhookconfiguration 是否存在；存在才 patch，避免 set -e 直接中止
# CACHE_WEBHOOK_NAME="cache-webhook-kubeflow"

# if kubectl get mutatingwebhookconfiguration "${CACHE_WEBHOOK_NAME}" &>/dev/null; then
#   echo "[INFO] Found mutatingwebhookconfiguration ${CACHE_WEBHOOK_NAME}, patching to only allow DELETE..."
#   kubectl patch mutatingwebhookconfiguration "${CACHE_WEBHOOK_NAME}" \
#     --type='json' \
#     -p='[{"op":"replace", "path": "/webhooks/0/rules/0/operations/0", "value": "DELETE"}]'
#   echo "[INFO] cache-webhook-kubeflow patched successfully."
# else
#   echo "[WARN] mutatingwebhookconfiguration ${CACHE_WEBHOOK_NAME} not found, skip cache webhook patch."
# fi

# echo "============================================================"
# echo "[7] 安裝 Central Dashboard"
# echo "============================================================"

# kustomize build applications/centraldashboard/overlays/oauth2-proxy | kubectl apply -f -
# kubectl wait --for=condition=Available --timeout=600s -n kubeflow deployment/centraldashboard

# echo "============================================================"
# echo "[8] Profiles + 預設使用者 (kubeflow-user-example-com)"
# echo "============================================================"

# # Profiles + KFAM
# kustomize build applications/profiles/upstream/overlays/kubeflow | kubectl apply -f -

# echo "============================================================"
# echo "[9] Admission Webhook（Notebook 等資源需要）"
# echo "============================================================"

# kustomize build applications/admission-webhook/upstream/overlays/cert-manager | kubectl apply -f -

# echo "============================================================"
# echo "[10] 安裝 Notebook / Volumes / PVC Viewer / Tensorboard (Web UI 相關)"
# echo "============================================================"

# # Notebook Controller
# kustomize build applications/jupyter/notebook-controller/upstream/overlays/kubeflow | kubectl apply -f -

# # Jupyter Web App
# kustomize build applications/jupyter/jupyter-web-app/upstream/overlays/istio | kubectl apply -f -

# # Volumes Web App
# kustomize build applications/volumes-web-app/upstream/overlays/istio | kubectl apply -f -

# # PVC Viewer Controller
# kustomize build applications/pvcviewer-controller/upstream/base | kubectl apply -f -

# # Tensorboard Controller
# kustomize build applications/tensorboard/tensorboard-controller/upstream/overlays/kubeflow | kubectl apply -f -

# # Tensorboards Web App
# kustomize build applications/tensorboard/tensorboards-web-app/upstream/overlays/istio | kubectl apply -f -

# echo "============================================================"
# echo "完成：Kubeflow 1.10.2 最小環境已套用（含 Pipelines cache webhook 關閉）。"
# echo "請稍等幾分鐘，讓所有 Pod 變成 Running / Completed。"
# echo "之後用瀏覽器連到 Istio Ingress 的位址，就可以看到 Kubeflow Dashboard。"
# echo "============================================================"

# # #error: kserver 缺少CRD
# # kustomize build applications/kserve/kserve | kubectl apply --server-side --force-conflicts -f -
# # kustomize build applications/kserve/models-web-app/overlays/kubeflow | kubectl apply -f -
# # kubectl get pods -n kubeflow

# # #error: training-operator 缺少CRD
# # kubectl apply --server-side --force-conflicts -k \
# #   "github.com/kubeflow/training-operator.git/manifests/overlays/standalone?ref=v1.9.2"

