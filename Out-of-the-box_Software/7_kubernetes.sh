# #!/bin/bash

# # =====================================================
# # environmental variables for central-env.common
# # =====================================================
# source ../Environmental_Variables/.env.common

# echo ""
# echo "##############################################################"
# echo "Download and save the GPG key :"
# echo ""
# mkdir -p /etc/apt/keyrings
# chmod 755 /etc/apt/keyrings

# curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Configure the Kubernetes APT package repository :"
# echo ""
# echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# cat /etc/apt/sources.list.d/kubernetes.list

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Update apt-get :"
# echo ""
# apt-get update

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Install kubelet kubeadm kubectl :"
# echo ""
# apt-get install kubelet kubeadm kubectl -y
# apt-mark hold kubelet kubeadm kubectl

# kubectl version --client 
# kubelet --version
# kubeadm version

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Close swap :"
# echo ""
# swapoff -a
# sed -i '/\/swapfile/s/^/# /' /etc/fstab # 將 /swapfile 這一行註解起來(前方加上 '#' )
# sed -i '/\/swap.img/s/^/# /' /etc/fstab # 將 /swapfile 這一行註解起來(前方加上 '#' )

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Init kubernetes :"
# echo ""
# kubeadm init --pod-network-cidr=10.244.0.0/16

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Create K8s cluster configuration file path for root:"
# echo ""

# mkdir -p /$USER/.kube
# sudo cp -i /etc/kubernetes/admin.conf /$USER/.kube/config
# sudo chown $(id -u):$(id -g) /$USER/.kube/config

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Install flannel :"
# echo ""
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Taint master node :"
# echo ""
# kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Wait for node mitlab status to become Ready... :"
# echo ""

# while true; do
#     # 獲取節點的狀態
#     NODE_STATUS=$(kubectl get node ubuntu -o=jsonpath='{.status.conditions[?(@.type=="Ready")].status}')

#     # 檢查節點是否處於 Ready 狀態
#     if [[ "${NODE_STATUS}" == "True" ]]; then
#         echo "Node mitlab status to be Ready "
#         break
#     else
#         echo "Node mitlab status not to be Ready"
#         # 等待 10 秒後重試
#         sleep 10
#     fi
# done

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Create containerd config :"
# echo ""

# mkdir -p /etc/containerd
# containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# # 定義目標檔案
# TARGET_FILE="/etc/containerd/config.toml"

# # 使用 sed 在指定行後插入
# MIRROR_ENTRY="\ \ \ \ \ \ \ \ [plugins.\"io.containerd.grpc.v1.cri\".registry.configs.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\".tls]"

# sed -i '/\[plugins\."io.containerd\.grpc\.v1\.cri"\.registry\.configs\]/a '"$MIRROR_ENTRY" "$TARGET_FILE"

# MATCH_TEXT="configs.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\""
# INSERT_TEXT='\ \ \ \ \ \ \ \ \ \ insecure_skip_verify = true'
# sed -i '/'"$MATCH_TEXT"'/a '"$INSERT_TEXT" "$TARGET_FILE"

# ########
# MIRROR_ENTRY="\ \ \ \ \ \ \ \ [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\"]"

# # 使用 sed 在指定行後插入
# sed -i '/\[plugins\."io.containerd\.grpc\.v1\.cri"\.registry\.mirrors\]/a '"$MIRROR_ENTRY" "$TARGET_FILE"

# MATCH_TEXT="mirrors.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\""
# INSERT_CONTENT="\ \ \ \ \ \ \ \ \ \ endpoint = [\"http://$CENTRAL_STORAGE_IP:$HARBOR_CONTAINER_PORT\"]"
# sed -i '/'"$MATCH_TEXT"'/a '"$INSERT_CONTENT" "$TARGET_FILE"

# # config.toml example
# # # configs 
# #       [plugins."io.containerd.grpc.v1.cri".registry.configs]
# #         [plugins."io.containerd.grpc.v1.cri".registry.configs."<CENTRAL_STORAGE_IP>:<IMG_MGT_CONTAINER_PORT>".tls]
# #           insecure_skip_verify = true
# # # mirrors
# #       [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
# #         [plugins."io.containerd.grpc.v1.cri".registry.mirrors."<CENTRAL_STORAGE_IP>:<IMG_MGT_CONTAINER_PORT>"]
# #           endpoint = ["http://<CENTRAL_STORAGE_IP>:<IMG_MGT_CONTAINER_PORT>"]

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Create K8s cluster configuration file path for user :"
# echo ""
# ORIGINAL_USER=$(logname)
# ORIGINAL_HOME=$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)

# mkdir -p $ORIGINAL_HOME/.kube
# sudo cp -i /etc/kubernetes/admin.conf $ORIGINAL_HOME/.kube/config
# sudo chown $(id -u "$ORIGINAL_USER"):$(id -g "$ORIGINAL_USER") $ORIGINAL_HOME/.kube/config

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Systemctl edit containerd :"
# echo ""
# # 定義目標 override 文件路徑
# OVERRIDE_FILE="/etc/systemd/system/containerd.service.d/override.conf"

# # 創建目標目錄（如果不存在）
# mkdir -p "$(dirname "$OVERRIDE_FILE")"

# # 向 override 文件中寫入配置
# cat <<EOF > "$OVERRIDE_FILE"
# [Service]
# ExecStart=
# ExecStart=/usr/bin/containerd --config /etc/containerd/config.toml
# EOF

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Restart daemon containerd and docker :"
# echo ""
# systemctl daemon-reload
# systemctl restart containerd
# systemctl restart docker

# echo "##############################################################"
source ../Environmental_Variables/.env.common

set -euo pipefail

# 取得原本登入的使用者（非 root）
ORIGINAL_USER=${SUDO_USER:-$(logname)}
ORIGINAL_HOME=$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)

echo ">>> Target kubectl user: ${ORIGINAL_USER} (${ORIGINAL_HOME})"

# ------------------------------------------------------------
# 1. Close swap
# ------------------------------------------------------------
echo ">>> [1] Disable swap"

swapoff -a
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
# 3. (如有需要) 安裝 containerd
# ------------------------------------------------------------
echo ">>> Generate default containerd config"
/bin/mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml

TARGET_FILE="/etc/containerd/config.toml"

# 啟用 systemd cgroup，與 kubelet 預設一致
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' "$TARGET_FILE"

# ------------------------------------------------------------
# 4. Configure containerd registry for Harbor (HTTP + insecure)
# ------------------------------------------------------------
echo ">>> [4] Configure containerd registry for Harbor (${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT})"

# 插入 configs (tls.insecure_skip_verify = true)
MIRROR_ENTRY="        [plugins.\"io.containerd.grpc.v1.cri\".registry.configs.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\".tls]"
sed -i '/\[plugins\."io.containerd\.grpc\.v1\.cri"\.registry\.configs\]/a '"$MIRROR_ENTRY" "$TARGET_FILE"

MATCH_TEXT="configs.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\""
INSERT_TEXT='          insecure_skip_verify = true'
sed -i '/'"$MATCH_TEXT"'/a '"$INSERT_TEXT" "$TARGET_FILE"

# 插入 mirrors (endpoint = ["http://IP:PORT"])
MIRROR_ENTRY2="        [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\"]"
sed -i '/\[plugins\."io.containerd\.grpc\.v1\.cri"\.registry\.mirrors\]/a '"$MIRROR_ENTRY2" "$TARGET_FILE"

MATCH_TEXT2="mirrors.\"${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\""
INSERT_CONTENT="          endpoint = [\"http://${CENTRAL_STORAGE_IP}:${HARBOR_CONTAINER_PORT}\"]"
sed -i '/'"$MATCH_TEXT2"'/a '"$INSERT_CONTENT" "$TARGET_FILE"

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
# 10. Copy kubeconfig to original login user
# ------------------------------------------------------------
echo ">>> [10] Copy kubeconfig to original user: ${ORIGINAL_USER}"

mkdir -p "${ORIGINAL_HOME}/.kube"

# ★ 修正：如果 ~/.kube/config 被誤建成目錄，先刪掉
if [ -d "${ORIGINAL_HOME}/.kube/config" ]; then
  rm -rf "${ORIGINAL_HOME}/.kube/config"
fi

cp -i /etc/kubernetes/admin.conf "${ORIGINAL_HOME}/.kube/config"
chown "$(id -u "$ORIGINAL_USER")":"$(id -g "$ORIGINAL_USER")" "${ORIGINAL_HOME}/.kube/config"

echo ">>> Copy kubeconfig to root user as well"

mkdir -p /root/.kube

# ★ 修正：同樣處理 root 的 ~/.kube/config 如果是目錄的情況
if [ -d /root/.kube/config ]; then
  rm -rf /root/.kube/config
fi

cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config

echo "============================================================"
echo "Kubernetes + containerd + flannel setup is DONE."
echo "You can now run (as ${ORIGINAL_USER}):"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo "============================================================"
