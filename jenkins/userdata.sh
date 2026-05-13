#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y ca-certificates curl gnupg unzip jq

# Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Terraform
TERRAFORM_VERSION="1.9.5"
curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o /tmp/terraform.zip
unzip -o /tmp/terraform.zip -d /usr/local/bin
chmod +x /usr/local/bin/terraform
rm /tmp/terraform.zip

# kubectl
curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

# AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -o /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

# Verify tools are installed before starting Jenkins
terraform version
kubectl version --client
aws --version

# Mount persistent EBS volume for Jenkins data
MOUNT_POINT="/mnt/jenkins-data"
DATA_DEVICE=""
# Wait up to 30s for EBS device to appear (NVMe attach can lag slightly)
for i in $(seq 1 6); do
  for dev in /dev/nvme1n1 /dev/xvdf; do
    if [ -b "$dev" ]; then DATA_DEVICE="$dev"; break 2; fi
  done
  echo "Waiting for EBS device... attempt $i/6"
  sleep 5
done
if [ -z "$DATA_DEVICE" ]; then
  echo "ERROR: data EBS device not found" >&2; exit 1
fi
mkdir -p "$MOUNT_POINT"
# Format only if no filesystem exists (preserves data on reattach)
if ! blkid "$DATA_DEVICE" | grep -q ext4; then
  mkfs.ext4 "$DATA_DEVICE"
fi
mount "$DATA_DEVICE" "$MOUNT_POINT"
echo "$DATA_DEVICE $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
chown -R 1000:1000 "$MOUNT_POINT"

# Start Jenkins with all tools mounted
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v "$MOUNT_POINT":/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/local/bin/terraform:/usr/local/bin/terraform \
  -v /usr/local/bin/kubectl:/usr/local/bin/kubectl \
  -v /usr/local/aws-cli:/usr/local/aws-cli \
  jenkins/jenkins:lts-jdk17

# Symlink aws CLI inside container as root
sleep 10
docker exec -u root jenkins ln -sf /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws

# Create a systemd service to re-symlink aws on every container restart
cat > /etc/systemd/system/jenkins-aws-symlink.service << 'EOF'
[Unit]
Description=Symlink AWS CLI inside Jenkins container
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'until docker exec -u root jenkins ln -sf /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws 2>/dev/null; do sleep 5; done'

[Install]
WantedBy=multi-user.target
EOF
systemctl enable jenkins-aws-symlink.service
