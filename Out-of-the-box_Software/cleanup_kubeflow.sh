#!/usr/bin/env bash
# ============================================================
# Kubeflow 1.9 + 相關元件完整移除腳本
# 適用情境：
#   - 用官方 manifests 安裝 Kubeflow 1.9
#   - 用 nfs-subdir-external-provisioner + nfs-client 當 StorageClass
#   - 安裝過：Kubeflow / KServe / Knative / Istio / cert-manager
#
# 使用方式：
#   chmod +x cleanup_kubeflow.sh
#   ./cleanup_kubeflow.sh
# ============================================================

set -o errexit
set -o nounset
set -o pipefail

echo "============================================================"
echo "[1] 定義一些輔助函式（安全地刪除資源）"
echo "============================================================"

# 安全刪 Namespace（不存在就略過）
kubectl_delete_ns_if_exists() {
  local ns="$1"
  if kubectl get ns "${ns}" &>/dev/null; then
    echo "  - 刪除 namespace: ${ns}"
    kubectl delete ns "${ns}" --wait=false
  else
    echo "  - namespace 不存在，略過: ${ns}"
  fi
}

# 安全卸載 Helm release
helm_uninstall_if_exists() {
  local release="$1"
  local ns="$2"
  if helm list -n "${ns}" 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "${release}"; then
    echo "  - 卸載 Helm release: ${release} (ns=${ns})"
    helm uninstall "${release}" -n "${ns}"
  else
    echo "  - Helm release 不存在，略過: ${release} (ns=${ns})"
  fi
}

# 安全刪 StorageClass
kubectl_delete_sc_if_exists() {
  local sc="$1"
  if kubectl get storageclass "${sc}" &>/dev/null; then
    echo "  - 刪除 StorageClass: ${sc}"
    kubectl delete storageclass "${sc}"
  else
    echo "  - StorageClass 不存在，略過: ${sc}"
  fi
}

# 安全刪 mutatingwebhookconfiguration / validatingwebhookconfiguration
kubectl_delete_mwc_if_exists() {
  local name="$1"
  if kubectl get mutatingwebhookconfiguration "${name}" &>/dev/null; then
    echo "  - 刪除 MutatingWebhookConfiguration: ${name}"
    kubectl delete mutatingwebhookconfiguration "${name}"
  else
    echo "  - MutatingWebhookConfiguration 不存在，略過: ${name}"
  fi
}

# 安全刪 CRD
kubectl_delete_crd_if_exists() {
  local crd="$1"
  if kubectl get crd "${crd}" &>/dev/null; then
    echo "  - 刪除 CRD: ${crd}"
    kubectl delete crd "${crd}"
  else
    echo "  - CRD 不存在，略過: ${crd}"
  fi
}

echo ""
echo "============================================================"
echo "[2] 卸載 NFS external provisioner + 刪除 kubeflow 相關 namespace"
echo "============================================================"

# 2-1. 卸載 NFS provisioner Helm release
helm_uninstall_if_exists "nfs-subdir-external-provisioner" "nfs-provisioner"

# 2-2. 刪除 Kubeflow 相關 namespaces（有就刪，沒有就略過）
for ns in \
  kubeflow \
  kubeflow-user-example-com \
  istio-system \
  knative-serving \
  knative-eventing \
  cert-manager \
  auth \
  oauth2-proxy \
  nfs-provisioner
do
  kubectl_delete_ns_if_exists "${ns}"
done

echo ""
echo "============================================================"
echo "[3] 刪除 nfs-client StorageClass"
echo "============================================================"

kubectl_delete_sc_if_exists "nfs-client"

echo ""
echo "============================================================"
echo "[4] 刪除 Kubeflow / KServe / Knative / Istio / cert-manager 的 Webhook"
echo "============================================================"

for mwc in \
  cache-webhook-kubeflow \
  katib.kubeflow.org \
  pvcviewer-mutating-webhook-configuration \
  admission-webhook-mutating-webhook-configuration \
  cert-manager-webhook \
  istio-sidecar-injector \
  inferenceservice.serving.kserve.io \
  sinkbindings.webhook.sources.knative.dev
do
  kubectl_delete_mwc_if_exists "${mwc}"
done

echo ""
echo "============================================================"
echo "[5] 刪除 Kubeflow 相關 CRD（含 profiles.finalizer 特殊處理）"
echo "============================================================"

# 5-1. 先處理 profiles.kubeflow.org（卡最兇的那個）
if kubectl get crd profiles.kubeflow.org &>/dev/null; then
  echo "  - 發現 CRD: profiles.kubeflow.org，先清掉 Profile finalizers"

  # 清除所有 Profiles 的 finalizer，避免刪除 CRD 卡住
  kubectl get profiles.kubeflow.org -o name 2>/dev/null | \
    xargs -I {} kubectl patch {} \
      -p '{"metadata":{"finalizers":[]}}' --type=merge || true

  # 刪掉所有 Profile 物件
  kubectl delete profiles.kubeflow.org --all 2>/dev/null || true

  # 刪除 profiles.kubeflow.org 這個 CRD
  kubectl_delete_crd_if_exists "profiles.kubeflow.org"
else
  echo "  - CRD profiles.kubeflow.org 不存在，略過 finalizer 處理"
fi

# 5-2. 刪除其他 Kubeflow 系列 CRD
for crd in \
  experiments.kubeflow.org \
  mpijobs.kubeflow.org \
  mxjobs.kubeflow.org \
  notebooks.kubeflow.org \
  paddlejobs.kubeflow.org \
  poddefaults.kubeflow.org \
  pvcviewers.kubeflow.org \
  pytorchjobs.kubeflow.org \
  scheduledworkflows.kubeflow.org \
  suggestions.kubeflow.org \
  tensorboards.tensorboard.kubeflow.org \
  tfjobs.kubeflow.org \
  trials.kubeflow.org \
  viewers.kubeflow.org \
  xgboostjobs.kubeflow.org
do
  kubectl_delete_crd_if_exists "${crd}"
done

echo ""
echo "============================================================"
echo "[6] 刪除 KServe CRD"
echo "============================================================"

for crd in \
  clusterservingruntimes.serving.kserve.io \
  clusterstoragecontainers.serving.kserve.io \
  inferencegraphs.serving.kserve.io \
  inferenceservices.serving.kserve.io \
  servingruntimes.serving.kserve.io \
  trainedmodels.serving.kserve.io
do
  kubectl_delete_crd_if_exists "${crd}"
done

echo ""
echo "============================================================"
echo "[7] 刪除 Knative CRD"
echo "============================================================"

for crd in \
  apiserversources.sources.knative.dev \
  brokers.eventing.knative.dev \
  certificates.networking.internal.knative.dev \
  channels.messaging.knative.dev \
  clusterdomainclaims.networking.internal.knative.dev \
  configurations.serving.knative.dev \
  containersources.sources.knative.dev \
  domainmappings.serving.knative.dev \
  eventtypes.eventing.knative.dev \
  images.caching.internal.knative.dev \
  ingresses.networking.internal.knative.dev \
  metrics.autoscaling.internal.knative.dev \
  parallels.flows.knative.dev \
  pingsources.sources.knative.dev \
  podautoscalers.autoscaling.internal.knative.dev \
  revisions.serving.knative.dev \
  routes.serving.knative.dev \
  sequences.flows.knative.dev \
  serverlessservices.networking.internal.knative.dev \
  services.serving.knative.dev \
  sinkbindings.sources.knative.dev \
  subscriptions.messaging.knative.dev \
  triggers.eventing.knative.dev
do
  kubectl_delete_crd_if_exists "${crd}"
done

echo ""
echo "============================================================"
echo "[8] 刪除 Istio CRD"
echo "============================================================"

for crd in \
  authorizationpolicies.security.istio.io \
  destinationrules.networking.istio.io \
  envoyfilters.networking.istio.io \
  gateways.networking.istio.io \
  peerauthentications.security.istio.io \
  proxyconfigs.networking.istio.io \
  requestauthentications.security.istio.io \
  serviceentries.networking.istio.io \
  sidecars.networking.istio.io \
  telemetries.telemetry.istio.io \
  virtualservices.networking.istio.io \
  wasmplugins.extensions.istio.io \
  workloadentries.networking.istio.io \
  workloadgroups.networking.istio.io
do
  kubectl_delete_crd_if_exists "${crd}"
done

echo ""
echo "============================================================"
echo "[9] 刪除 cert-manager CRD"
echo "============================================================"

for crd in \
  certificaterequests.cert-manager.io \
  certificates.cert-manager.io \
  challenges.acme.cert-manager.io \
  clusterissuers.cert-manager.io \
  issuers.cert-manager.io \
  orders.acme.cert-manager.io
do
  kubectl_delete_crd_if_exists "${crd}"
done

echo ""
echo "============================================================"
echo "[10] 刪除只跟 Kubeflow 有關的 PV（可依需要自行調整）"
echo "============================================================"

# 注意：
#   這裡只示範刪掉名稱已知、且 StorageClass 是 nfs-client 的 PV。
#   如果你的 PV 名稱不同，請改成自己的名稱或註解掉這一段手動處理。
for pv in \
  pvc-62fbf98e-2eef-4932-a0d3-2bcede1beecb \
  pvc-9558096e-a538-4002-8b98-98b76bf368c4 \
  pvc-9d9c9f9f-d659-49ea-9452-00c65adc8172
do
  if kubectl get pv "${pv}" &>/dev/null; then
    echo "  - 刪除 PV: ${pv}"
    kubectl delete pv "${pv}"
  else
    echo "  - PV 不存在，略過: ${pv}"
  fi
done

echo ""
echo "============================================================"
echo "[11]（選填）本機清理 Kubeflow 資料與工具檔案"
echo "============================================================"
echo "  * 下列操作不自動執行，請視情況手動執行："
echo "    - 刪除 /nfs/kubeflow 下面的舊 PVC 目錄"
echo "    - 刪除 Kubeflow manifests repo 與 /usr/bin/kustomize"

cat <<'EOF'

# === 以下為「可選」清理步驟，請依實際環境決定要不要用 ===
# 在 NFS server 或本機（取決於你實際的 NFS 路徑）執行：

# cd /nfs/kubeflow
# sudo rm -rf kubeflow-mysql-pv-claim-pvc-9d9c9f9f-d659-49ea-9452-00c65adc8172
# sudo rm -rf kubeflow-minio-pvc-pvc-62fbf98e-2eef-4932-a0d3-2bcede1beecb
# sudo rm -rf kubeflow-katib-mysql-pvc-9558096e-a538-4002-8b98-98b76bf368c4

# 若當初有 clone Kubeflow manifests 並把 kustomize 丟到 /usr/bin：
# cd ~
# rm -rf manifests
# sudo rm -f /usr/bin/kustomize

EOF

echo ""
echo "============================================================"
echo "✅ Kubeflow 相關元件清除流程完成（請再手動檢查一次 kubectl get ns / get crd / get pv）"
echo "============================================================"
