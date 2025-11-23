#!/bin/bash
set -euo pipefail

# ============================================================
# 0. 載入環境變數（主要是 NFS 的 IP / 路徑 + Harbor 設定）
# ============================================================
source ../Environmental_Variables/.env.common

# ============================================================
# 0.1 設定兩個 Harbor Registry
# ============================================================
# 1) Kubeflow 用的 Harbor Proxy Cache（改寫 ghcr.io → 這個 registry）
HARBOR_PROXY_HOST="140.118.162.139:35301"

# 2) 訓練用 image 所在的 Harbor（例如 140.118.162.95:32000 這種）
TRAIN_REGISTRY_HOST="${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}"

# 取得原本登入的使用者（非 root）
ORIGINAL_USER=${SUDO_USER:-$(logname)}
ORIGINAL_HOME=$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)

echo ">>> Target kubectl user: ${ORIGINAL_USER} (${ORIGINAL_HOME})"

# ------------------------------------------------------------
# 1. Disable swap
# ------------------------------------------------------------
echo ">>> [1] Disable swap"

swapoff -a || true
# 把常見的 swap 設定註解掉
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab || true
sed -i '/\/swapfile/s/^/# /' /etc/fstab || true
sed -i '/\/swap.img/s/^/# /' /etc/fstab || true

# ------------------------------------------------------------
# 2. Sysctl and kernel modules
# ------------------------------------------------------------
echo ">>> [2] Configure sysctl and kernel modules"

# 確保模組載入
modprobe overlay || true
modprobe br_netfilter || true

# 開機自動載入模組
cat <<EOF >/etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

# 設定網路相關 sysctl
cat <<EOF >/etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# ------------------------------------------------------------
# 3. 產生 containerd 預設設定檔 + 啟用 systemd cgroup
# ------------------------------------------------------------
echo ">>> [3] Generate default containerd config"

mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml

TARGET_FILE="/etc/containerd/config.toml"

# 啟用 systemd cgroup，與 kubelet 預設一致
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' "$TARGET_FILE" || true

# ------------------------------------------------------------
# 4. 調整 containerd registry：啟用 config_path，並為兩個 Harbor 建 hosts.toml
# ------------------------------------------------------------
echo ">>> [4] Configure containerd registry for Harbor Proxy (${HARBOR_PROXY_HOST}) and Train Harbor (${TRAIN_REGISTRY_HOST})"

# 4-1) 啟用 registry.config_path = "/etc/containerd/certs.d"
# 預設 config 會有一行：config_path = ""
if grep -q 'config_path = ""' "$TARGET_FILE"; then
  sed -i 's#config_path = ""#config_path = "/etc/containerd/certs.d"#' "$TARGET_FILE"
else
  # 若沒有，則在 registry 區塊塞一行（一般不會走到這裡，但保險一下）
  sed -i 's/\[plugins\."io.containerd.grpc.v1.cri"\.registry\]/[plugins."io.containerd.grpc.v1.cri".registry]\n  config_path = "\/etc\/containerd\/certs.d"/' "$TARGET_FILE"
fi

# （重要）不再使用 registry.mirrors 來轉 ghcr.io，避免 /v2 路徑對不起來
# 我們改用 hosts.toml 來直接宣告每一個 registry。

# 4-2) 為 Kubeflow Harbor Proxy 建立 hosts.toml，宣告它是一個 HTTP registry，可以 pull / resolve
mkdir -p "/etc/containerd/certs.d/${HARBOR_PROXY_HOST}"

cat >"/etc/containerd/certs.d/${HARBOR_PROXY_HOST}/hosts.toml" <<EOF
server = "http://${HARBOR_PROXY_HOST}"

[host."http://${HARBOR_PROXY_HOST}"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF

# 4-3) 為「訓練用 Harbor」建立 hosts.toml，讓節點可以從這裡拉訓練 image
mkdir -p "/etc/containerd/certs.d/${TRAIN_REGISTRY_HOST}"

cat >"/etc/containerd/certs.d/${TRAIN_REGISTRY_HOST}/hosts.toml" <<EOF
server = "http://${TRAIN_REGISTRY_HOST}"

[host."http://${TRAIN_REGISTRY_HOST}"]
  # 如果之後要從節點 push image 上去，可以加上 "push"
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF

echo ">>> containerd registry config_path = /etc/containerd/certs.d"
echo ">>> hosts.toml created for:"
echo "    - ${HARBOR_PROXY_HOST} (Kubeflow Proxy Cache)"
echo "    - ${TRAIN_REGISTRY_HOST} (Training Images Harbor)"

# ------------------------------------------------------------
# 5. systemd override for containerd
# ------------------------------------------------------------
echo ">>> [5] Configure systemd override for containerd"

OVERRIDE_FILE="/etc/systemd/system/containerd.service.d/override.conf"
mkdir -p "$(dirname "$OVERRIDE_FILE")"

cat <<EOF >"$OVERRIDE_FILE"
[Service]
ExecStart=
ExecStart=/usr/bin/containerd --config /etc/containerd/config.toml
EOF

systemctl daemon-reload
systemctl restart containerd

echo ">>> containerd restarted. You can verify with: crictl info | sed -n '/\"registry\"/,/\"sandboxImage\"/p'"

# ------------------------------------------------------------
# 6. Install Kubernetes repo & packages
# ------------------------------------------------------------
echo ">>> [6] Install Kubernetes 1.32 repository and packages"

mkdir -p /etc/apt/keyrings
chmod 755 /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /
EOF

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# ------------------------------------------------------------
# 7. kubeadm init
# ------------------------------------------------------------
echo ">>> [7] Run kubeadm init"

kubeadm init --pod-network-cidr=10.244.0.0/16 --v=5

# 之後整個 script 用 admin.conf 當 kubeconfig
export KUBECONFIG=/etc/kubernetes/admin.conf

# 讓 control-plane 也能排工作負載
echo ">>> Remove control-plane taint (allow scheduling on master)"
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# ------------------------------------------------------------
# 8. Install flannel CNI and wait
# ------------------------------------------------------------
echo ">>> [8] Install flannel CNI"

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

echo ">>> Wait for flannel pods to be Ready..."
while true; do
  READY=$(kubectl get pod -n kube-flannel -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>/dev/null | grep -c true || true)
  if [[ "$READY" -ge 1 ]]; then
    echo ">>> flannel is Ready."
    break
  else
    echo ">>> flannel is still starting, retry in 10 seconds..."
    sleep 10
  fi
done

# ------------------------------------------------------------
# 9. Wait for node Ready
# ------------------------------------------------------------
echo ">>> [9] Wait for node to become Ready..."

while true; do
  NODE_STATUS=$(kubectl get node -o=jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' || echo "False")
  if [[ "${NODE_STATUS}" == "True" ]]; then
    NODE_NAME=$(kubectl get node -o=jsonpath='{.items[0].metadata.name}')
    echo ">>> Node ${NODE_NAME} is Ready!"
    break
  else
    echo ">>> Node is not Ready yet, retry in 10 seconds..."
    sleep 10
  fi
done

# ------------------------------------------------------------
# 10. Copy kubeconfig to original login user + root
# ------------------------------------------------------------
echo ">>> [10] Copy kubeconfig to original user: ${ORIGINAL_USER}"

mkdir -p "${ORIGINAL_HOME}/.kube"

# 如果 ~/.kube/config 被誤建成目錄，先刪掉
if [ -d "${ORIGINAL_HOME}/.kube/config" ]; then
  rm -rf "${ORIGINAL_HOME}/.kube/config"
fi

cp -i /etc/kubernetes/admin.conf "${ORIGINAL_HOME}/.kube/config"
chown "$(id -u "$ORIGINAL_USER")":"$(id -g "$ORIGINAL_USER")" "${ORIGINAL_HOME}/.kube/config"

echo ">>> Copy kubeconfig to root user as well"

mkdir -p /root/.kube

if [ -d /root/.kube/config ]; then
  rm -rf /root/.kube/config
fi

cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config

echo "============================================================"
echo "Kubernetes + containerd + flannel + TWO Harbor registries setup is DONE."
echo "Harbor Proxy (Kubeflow images):          ${HARBOR_PROXY_HOST}"
echo "Train Harbor (training images registry): ${TRAIN_REGISTRY_HOST}"
echo "You can now run (as ${ORIGINAL_USER}):"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo "============================================================"
