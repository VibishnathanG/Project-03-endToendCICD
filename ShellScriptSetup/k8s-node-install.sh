#!/bin/bash

hostnamectl set-hostname workernode
setenforce 0
sudo swapoff -a

#############################

sudo apt-get update -y

###########################################

Echo "containerd install"

echo "Make script executable using chmod u+x FILE_NAME.sh"

echo "Containerd installation script"
echo "Instructions from https://kubernetes.io/docs/setup/production-environment/container-runtimes/"

echo "Creating containerd configuration file with list of necessary modules that need to be loaded with containerd"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

echo "Load containerd modules"
sudo modprobe overlay
sudo modprobe br_netfilter


echo "Creates configuration file for kubernetes-cri file (changed to k8s.conf)"
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

echo "Applying sysctl params"
sudo sysctl --system


echo "Verify that the br_netfilter, overlay modules are loaded by running the following commands:"
lsmod | grep br_netfilter
lsmod | grep overlay

echo "Verify that the net.bridge.bridge-nf-call-iptables, net.bridge.bridge-nf-call-ip6tables, and net.ipv4.ip_forward system variables are set to 1 in your sysctl config by running the following command:"
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

echo "Update packages list"
sudo apt-get update

echo "Install containerd"
sudo apt-get -y install containerd

echo "Create a default config file at default location"
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

echo "Restarting containerd"
sudo systemctl restart containerd

service containerd status

echo "Contained Install Completed"

#####################################################################


echo "Kubeadm Kubelet Kubectl Install Start....."

sudo apt-get update

# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg


curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

echo "Installing latest versions"
sudo apt-get install -y kubelet kubeadm kubectl

echo "Fixate version to prevent upgrades"
sudo apt-mark hold kubelet kubeadm kubectl

kubeadm version
service kubelet status

echo "Kubeadm Kubelet Kubectl Install completed....."

sleep 30

# Define the path to the config file
CONFIG_FILE="/etc/containerd/config.toml"

# Check if the file exists before proceeding
if [ -f "$CONFIG_FILE" ]; then
    # Use sed to replace the value in the config file
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' "$CONFIG_FILE"
    echo "Updated SystemdCgroup setting in $CONFIG_FILE"
else
    echo "Config file $CONFIG_FILE not found!"
fi


sudo service containerd restart
sudo service kubelet restart


sleep 60


echo "Please run Join CMD from Master node CMD for getting Join cmd is ----> kubeadm token create --print-join-command"

echo "If Need kubectl to be runned in worker Node also copy the admin conf from master and paste in $home/.kube/config
and provide the permmsions and restart Kubelet"