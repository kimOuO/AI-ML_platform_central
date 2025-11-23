#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# ============================================================
# 0. 載入環境變數
#    需要 CENTRAL_STORAGE_IP / NFS_SERVER_PATH / HARBOR_PROXY_REGISTRY 等
# ============================================================
source ../Environmental_Variables/.env.common

# Kubeflow namespace（預設 kubeflow）
KFP_NAMESPACE="kubeflow"

# ============================================================
# 0.1 Harbor Proxy 設定：把 ghcr.io 改成 Harbor Proxy
# ============================================================
# 之後所有 kustomize build 出來的 YAML，只要有 ghcr.io/ 開頭的 image，
# 都會被 rewrite 成：${HARBOR_PROXY_REGISTRY}/...
HARBOR_PROXY_REGISTRY="${HARBOR_PROXY_REGISTRY:-140.118.162.139:35301/ghcr}"

rewrite_ghcr_to_harbor() {
  # 把 YAML 裡所有 ghcr.io/... 改成 ${HARBOR_PROXY_REGISTRY}/...
  sed "s#ghcr.io/#${HARBOR_PROXY_REGISTRY}/#g"
}

kf_apply() {
  local path="$1"
  echo "[KF+Harbor] kustomize build ${path} | rewrite_ghcr_to_harbor | kubectl apply -f -"
  kustomize build "${path}" \
    | rewrite_ghcr_to_harbor \
    | kubectl apply -f -
}

echo "##############################################################"
echo "Set NFS server for kubeflow:"
echo "##############################################################"
echo ""

# ------------------------------------------------------------
# 1. 安裝 NFS Subdir External Provisioner
# ------------------------------------------------------------
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

# 這裡改成「寫死」的 IP + 路徑
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --create-namespace \
  --namespace nfs-provisioner \
  --set nfs.server=${CENTRAL_STORAGE_IP} \
  --set nfs.path=${NFS_SERVER_PATH}

# ================== 設定 nfs-client 為預設 StorageClass，避免 PVC Pending ==================
echo "============================================================"
echo "[NFS] 設定 nfs-client 為預設 StorageClass，避免 PVC 沒指定時卡 Pending"
echo "============================================================"

# 等待 nfs-client StorageClass 建立（最多等 30 次，每次 5 秒）
for i in {1..30}; do
  if kubectl get sc nfs-client >/dev/null 2>&1; then
    echo "[INFO] 找到 StorageClass nfs-client"
    break
  fi
  echo "[INFO] 等待 nfs-client StorageClass 建立中 (${i}/30)..."
  sleep 5
done

# 將 nfs-client 設為 default StorageClass（若失敗只印 WARNING，不中斷整個腳本）
if kubectl get sc nfs-client >/dev/null 2>&1; then
  kubectl patch storageclass nfs-client \
    -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' \
    && echo "[INFO] 已將 nfs-client 設為預設 StorageClass" \
    || echo "[WARN] 設定 nfs-client 為預設 StorageClass 失敗，請手動檢查"
else
  echo "[WARN] 仍然找不到 StorageClass nfs-client，PVC 可能會卡 Pending，請手動檢查"
fi
# ================== NFS 區塊結束 ================================================================

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Build kubeflow :"
echo "##############################################################"
echo ""
# ------------------------------------------------------------
# 2. 下載 Kubeflow manifests 與 kustomize
# ------------------------------------------------------------
git clone https://github.com/kubeflow/manifests.git
cd manifests
git checkout v1.10-branch
wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.4.3/kustomize_v5.4.3_linux_amd64.tar.gz

# Unzip kustomize and Configure kustomize
tar -xzvf kustomize_v5.4.3_linux_amd64.tar.gz
chmod 777 kustomize
mv kustomize /usr/bin/kustomize

# ------------------------------------------------------------
# 2.5 先建立 kubeflow namespace（避免後面一堆 namespaces "kubeflow" not found）
# ------------------------------------------------------------
echo "============================================================"
echo "[2.5] 建立 kubeflow namespace"
echo "============================================================"

kubectl create namespace "${KFP_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# ------------------------------------------------------------
# 3. 安裝 cert-manager
# ------------------------------------------------------------
echo "============================================================"
echo "[3] 安裝 cert-manager"
echo "============================================================"

# 1) 先安裝 cert-manager 本體
kf_apply common/cert-manager/base

# 2) 等 deployment Ready（含 webhook）
kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager
kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager-webhook
kubectl wait --for=condition=Available --timeout=300s -n cert-manager deployment/cert-manager-cainjector

# 3) 再安裝 Kubeflow issuer（這時 webhook 已經 ready）
kf_apply common/cert-manager/kubeflow-issuer/base

# ------------------------------------------------------------
# 4. 安裝 Istio (Kubeflow 預設設定)
# ------------------------------------------------------------
echo "============================================================"
echo "[4] 安裝 Istio (Kubeflow 預設設定)"
echo "============================================================"

# Istio CRDs
kf_apply common/istio/istio-crds/base
# Istio namespace + 基本設定
kf_apply common/istio/istio-namespace/base
# Istio 安裝（使用 oauth2-proxy overlay）
kf_apply common/istio/istio-install/overlays/oauth2-proxy

kubectl wait --for=condition=Available --timeout=600s -n istio-system deployment/istiod
kubectl wait --for=condition=Available --timeout=600s -n istio-system deployment/istio-ingressgateway

# ------------------------------------------------------------
# 5. OAuth2-proxy + Dex（登入機制）
# ------------------------------------------------------------
echo "============================================================"
echo "[5] OAuth2-proxy + Dex（登入機制）"
echo "============================================================"

# OAuth2-proxy
kf_apply common/oauth2-proxy/overlays/m2m-dex-only/
kubectl wait --for=condition=Available --timeout=300s -n oauth2-proxy deployment/oauth2-proxy

# Dex（預設帳密：user@example.com / 12341234）
kf_apply common/dex/overlays/oauth2-proxy
kubectl wait --for=condition=Available --timeout=300s -n auth deployment/dex

# ------------------------------------------------------------
# 6. NetworkPolicy + RBAC + Kubeflow 的 Istio 資源 + Pipelines Core
# ------------------------------------------------------------
echo "============================================================"
echo "[6] NetworkPolicy + RBAC + Kubeflow 的 Istio 資源 + Pipelines"
echo "============================================================"

# NetworkPolicy
kf_apply common/networkpolicies/base

# Kubeflow Roles (ClusterRoles / ClusterRoleBindings 等)
kf_apply common/kubeflow-roles/base

# Kubeflow Istio 資源（VirtualService / Gateway 等）
kf_apply common/istio/kubeflow-istio-resources/base

# Kubeflow Pipelines (multi-user, cert-manager 版本)
# 部分環境會跳 DecoratorController / namespace 等警告，但不影響後續，可忽略
set +o errexit
kf_apply applications/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user || \
  echo "[WARN] Some Pipeline resources may have failed on first apply (e.g. DecoratorController). You can re-run this kustomize later if needed."
set -o errexit

# 先等 ml-pipeline-ui 起來（如果還沒建成功會 timeout，但腳本會照規則等）
kubectl wait --for=condition=Available --timeout=600s -n "${KFP_NAMESPACE}" deployment/ml-pipeline-ui || \
  echo "[WARN] ml-pipeline-ui not Ready yet. Please check later with: kubectl get pods -n ${KFP_NAMESPACE}"

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
  if kubectl -n "${KFP_NAMESPACE}" get destinationrule "${dr}" &>/dev/null; then
    echo "  - Patching DestinationRule: ${dr}"
    kubectl -n "${KFP_NAMESPACE}" patch destinationrule "${dr}" \
      --type='json' \
      -p='[{"op":"replace","path":"/spec/trafficPolicy/tls","value":{"mode":"DISABLE"}}]'
  else
    echo "  - DestinationRule ${dr} not found, skip."
  fi
done

# ------------------------------------------------------------
# 6.3 修復 Kubeflow Pipelines 使用的 MySQL（root 帳號 / plugin / DB）
# ------------------------------------------------------------
echo "============================================================"
echo "[6.3] 修復 Kubeflow MySQL 設定（root plugin + metadb/mlpipeline/cachedb）"
echo "============================================================"

echo "[MySQL Fix] 尋找 MySQL Pod (label app=mysql, namespace=${KFP_NAMESPACE})"

MYSQL_POD=""
for i in {1..30}; do
  MYSQL_POD=$(kubectl -n "${KFP_NAMESPACE}" get pod -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  if [[ -n "${MYSQL_POD}" ]]; then
    PHASE=$(kubectl -n "${KFP_NAMESPACE}" get pod "${MYSQL_POD}" -o jsonpath='{.status.phase}' || echo "Unknown")
    echo "[INFO] 找到 MySQL Pod: ${MYSQL_POD}, phase=${PHASE}"
    if [[ "${PHASE}" == "Running" ]]; then
      break
    fi
  else
    echo "[INFO] 尚未找到 MySQL Pod，等待中 (${i}/30)..."
  fi
  sleep 5
done

if [[ -z "${MYSQL_POD}" ]]; then
  echo "[ERROR] 無法在 namespace=${KFP_NAMESPACE} 找到 app=mysql 的 Pod，請確認 Kubeflow Pipelines 是否已安裝。"
  exit 1
fi

# 🔥 新增：等待 mysqld 真的 Ready（避免 socket 連不到）
echo "[MySQL Fix] 等待 mysqld ready（mysqladmin ping）..."

MYSQL_READY=0
for i in {1..60}; do
  if kubectl -n "${KFP_NAMESPACE}" exec "${MYSQL_POD}" -- \
       sh -c "mysqladmin ping -u root --silent" >/dev/null 2>&1; then
    echo "[INFO] MySQL 已經就緒（mysqld 回應 ping）。"
    MYSQL_READY=1
    break
  fi
  echo "[INFO] MySQL 尚未 ready，重試中 (${i}/60)..."
  sleep 5
done

if [[ "${MYSQL_READY}" -ne 1 ]]; then
  echo "[ERROR] 等待 mysqld 超時，仍然無法 ping 通，請先手動檢查 MySQL Pod log。"
  exit 1
fi

echo "[MySQL Fix] 在 MySQL 中修正 root 帳號 / plugin / 建立 DB"

kubectl -n "${KFP_NAMESPACE}" exec "${MYSQL_POD}" -- mysql -u root << 'EOSQL'
-- =========================================================
-- 調整 root 帳號：
--   - root@localhost / root@'%' 使用 mysql_native_password + 空密碼
--   - root@'%' 允許從其他 Pod 連線
-- =========================================================

ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';

CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED WITH mysql_native_password BY '';

GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;

-- =========================================================
-- 建立 Kubeflow 需要的三個 DB（若不存在）
--   - metadb      : 給 metadata-grpc (MLMD)
--   - mlpipeline  : 給 ml-pipeline / persistenceagent / scheduledworkflow
--   - cachedb     : 給 cache-server
-- =========================================================
CREATE DATABASE IF NOT EXISTS metadb;
CREATE DATABASE IF NOT EXISTS mlpipeline;
CREATE DATABASE IF NOT EXISTS cachedb;
EOSQL

echo "[MySQL Fix] MySQL 初始化 SQL 執行完成，檢查當前狀態："

echo "[INFO] 使用者 plugin 狀態 (應該看到 root@'%' 與 root@'localhost' 為 mysql_native_password)："
kubectl -n "${KFP_NAMESPACE}" exec "${MYSQL_POD}" -- \
  mysql -u root -e "SELECT user, host, plugin FROM mysql.user;"

echo ""
echo "[INFO] 資料庫列表 (應該至少有 metadb / mlpipeline / cachedb)："
kubectl -n "${KFP_NAMESPACE}" exec "${MYSQL_POD}" -- \
  mysql -u root -e "SHOW DATABASES;"

# ------------------------------------------------------------
# 6.4 重啟 Pipelines 相關 Pod（套用 DestinationRule + MySQL 修復）
# ------------------------------------------------------------
echo "============================================================"
echo "[6.4] 重啟 Kubeflow Pipelines Pods（套用 TLS 設定與 MySQL 修復結果）"
echo "============================================================"

echo "[INFO] Restart Kubeflow Pipelines Pods to pick up new DestinationRule and MySQL settings..."
kubectl -n "${KFP_NAMESPACE}" delete pod -l application-crd-id=kubeflow-pipelines --ignore-not-found

# ------------------------------------------------------------
# 7. 安裝 Central Dashboard
# ------------------------------------------------------------
echo "============================================================"
echo "[7] 安裝 Central Dashboard"
echo "============================================================"

kf_apply applications/centraldashboard/overlays/oauth2-proxy

kubectl wait --for=condition=Available --timeout=600s -n "${KFP_NAMESPACE}" deployment/centraldashboard || \
  echo "[WARN] centraldashboard not Ready yet. Please check: kubectl get pods -n ${KFP_NAMESPACE}"

# ------------------------------------------------------------
# 8. Profiles + 預設使用者 (kubeflow-user-example-com)
# ------------------------------------------------------------
echo "============================================================"
echo "[8] Profiles + 預設使用者 (kubeflow-user-example-com)"
echo "============================================================"

# Profiles + KFAM（安裝 CRD / controller）
kf_apply applications/profiles/upstream/overlays/kubeflow

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

# ================== [8.1 修正版] 同步 mlpipeline-minio-artifact Secret 到 user namespace ==================
echo "============================================================"
echo "[8.1] 同步 mlpipeline-minio-artifact Secret 到 kubeflow-user-example-com"
echo "============================================================"

# 先等 Profile 幫忙建立 namespace kubeflow-user-example-com（最多等 30 次，每次 5 秒）
for i in {1..30}; do
  if kubectl get namespace kubeflow-user-example-com >/dev/null 2>&1; then
    echo "[INFO] Profile namespace kubeflow-user-example-com 已建立"
    break
  fi
  echo "[INFO] 等待 namespace kubeflow-user-example-com 建立中 (${i}/30)..."
  sleep 5
done

if kubectl get namespace kubeflow-user-example-com >/dev/null 2>&1; then
  # 確認在 kubeflow namespace 裡有這個 Secret 再複製
  if kubectl -n "${KFP_NAMESPACE}" get secret mlpipeline-minio-artifact >/dev/null 2>&1; then
    kubectl get secret mlpipeline-minio-artifact -n "${KFP_NAMESPACE}" -o yaml \
      | sed "s/namespace: ${KFP_NAMESPACE}/namespace: kubeflow-user-example-com/" \
      | kubectl apply -f - \
      && echo "[INFO] 已將 mlpipeline-minio-artifact Secret 複製到 kubeflow-user-example-com" \
      || echo "[WARN] 複製 mlpipeline-minio-artifact Secret 失敗，請手動檢查"
  else
    echo "[WARN] 在 ${KFP_NAMESPACE} namespace 找不到 mlpipeline-minio-artifact Secret，略過複製動作"
  fi
else
  echo "[WARN] namespace kubeflow-user-example-com 遲遲沒有建立，略過 Secret 複製，請手動檢查"
fi
# ================== [8.1 修正版區塊結束] ================================================================

# ------------------------------------------------------------
# 9. Admission Webhook（Notebook 等資源需要）
# ------------------------------------------------------------
echo "============================================================"
echo "[9] Admission Webhook（Notebook 等資源需要）"
echo "============================================================"

kf_apply applications/admission-webhook/upstream/overlays/cert-manager

# ------------------------------------------------------------
# 10. Notebook / Volumes / PVC Viewer / Tensorboard
# ------------------------------------------------------------
echo "============================================================"
echo "[10] 安裝 Notebook / Volumes / PVC Viewer / Tensorboard (Web UI 相關)"
# ------------------------------------------------------------

# Notebook Controller
kf_apply applications/jupyter/notebook-controller/upstream/overlays/kubeflow

# Jupyter Web App
kf_apply applications/jupyter/jupyter-web-app/upstream/overlays/istio

# Volumes Web App
kf_apply applications/volumes-web-app/upstream/overlays/istio

# PVC Viewer Controller
kf_apply applications/pvcviewer-controller/upstream/base

# Tensorboard Controller
kf_apply applications/tensorboard/tensorboard-controller/upstream/overlays/kubeflow

# Tensorboards Web App
kf_apply applications/tensorboard/tensorboards-web-app/upstream/overlays/istio

echo "============================================================"
echo "[DONE] Kubeflow with Harbor Proxy (GHCR → ${HARBOR_PROXY_REGISTRY}) + MySQL 修復流程完成"
echo "============================================================"
