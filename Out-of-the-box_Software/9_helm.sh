# #!/bin/bash

# echo ""
# echo "##############################################################"
# echo "Set up the Helm repository :"
# echo ""
# curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
# apt-get install apt-transport-https -y
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Update apt-get :"
# echo ""
# apt-get update

# echo "##############################################################"

# echo ""
# echo "##############################################################"
# echo "Install helm :"
# echo ""

# apt-get install helm

# echo "##############################################################"
#!/bin/bash

echo ""
echo "##############################################################"
echo "Set up the Helm repository :"
echo ""

# 新的 Buildkite 倉庫路徑（取代 baltocdn）
sudo apt-get install -y curl gpg apt-transport-https

curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey \
  | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" \
  | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Update apt-get :"
echo ""
apt-get update

echo "##############################################################"

echo ""
echo "##############################################################"
echo "Install helm :"
echo ""

apt-get install -y helm

echo "##############################################################"
