#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y ca-certificates curl gnupg unzip

# Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Mount persistent EBS volume for Jenkins data
# Newer instance types expose EBS as NVMe; wait for the device to appear
MOUNT_POINT="/mnt/jenkins-data"
DATA_DEVICE=""
for dev in /dev/nvme1n1 /dev/xvdf; do
  if [ -b "$dev" ]; then DATA_DEVICE="$dev"; break; fi
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

# Jenkins via Docker (avoids expired apt repo GPG key issue)
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

# Symlink aws CLI inside container (runs as root)
sleep 5
docker exec -u root jenkins ln -sf /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws

# Terraform
TERRAFORM_VERSION="1.9.5"
curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o /tmp/terraform.zip
unzip /tmp/terraform.zip -d /usr/local/bin
rm /tmp/terraform.zip

# kubectl
curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

# AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws
