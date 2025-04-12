#!/bin/bash

# Enable allexport to load environment variables from .env file
set -o allexport
source .env
set +o allexport

# Determine the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Remove existing talos config file to ensure a clean setup
rm -f ~/talos/config

# Print the control plane IP for debugging/verification
echo ${CP_IP}

# Change to the script's directory
cd ${SCRIPT_DIR}/

# Remove and recreate the main directory structure for Talos configuration
rm -rf ${MAIN_DIRECTORY}
mkdir -p ${MAIN_DIRECTORY}
mkdir -p ${MAIN_DIRECTORY}/ControlPlane
mkdir -p ${MAIN_DIRECTORY}/Common 
mkdir -p ${MAIN_DIRECTORY}/Worker
cd ${MAIN_DIRECTORY}/

# Navigate to Common directory to create Tailscale patch configuration
pushd Common > /dev/null
cat << EOF > tailscale.patch.yaml
---
apiVersion: v1alpha1
kind: ExtensionServiceConfig
name: tailscale
environment:
  - TS_AUTHKEY=${TS_AUTH_KEY}
EOF
popd > /dev/null

# Generate Talos configuration for the control plane
echo "GENERATING TALOS CONFIG"
IP_ONLY="${CP_IP%/*}"  # Extract IP without subnet mask
echo "talosctl gen config $CP_HOSTNAME https://$IP_ONLY:6443 --install-image $image --install-disk $disk --with-docs=false --with-examples=false"
talosctl gen config $CP_HOSTNAME https://$IP_ONLY:6443 --install-image $image --install-disk $disk --with-docs=false --with-examples=false

# Move generated YAML files to their respective directories
mv controlplane.yaml ControlPlane/
mv worker.yaml Worker/
mv talosconfig Remote/

# Set up Talos config file in the user's home directory
echo "SETTING UP TALOSCONFIG"
mkdir -p ~/.talos
cp Remote/talosconfig ~/.talos/config

# Configure control plane settings
pushd ControlPlane > /dev/null

# Enable disk wipe for fresh installation
echo "DISK WIPE PROPERTY TRUE"
yq e '.machine.install.wipe =true' -i controlplane.yaml

# Set the hostname for the control plane
echo "SETTING UP HOSTNAME"
yq e '.machine.network.hostname= "'$CP_HOSTNAME'"' -i controlplane.yaml

# Configure network settings: nameservers, interfaces, routes, and time servers
yq e '.machine.network.nameservers |= ["8.8.8.8", "8.8.4.4", "'$Gateway'"]' -i controlplane.yaml
yq e '.machine.network.interfaces |= [{"interface":"'$Interface'","addresses":["'$CP_IP'"],"routes":[{"network":"0.0.0.0/0","gateway":"'$Gateway'"}],"dhcp":false}]' -i controlplane.yaml
yq e '.machine.time.servers |= ["time.google.com"]' -i controlplane.yaml
yq e '.machine.network.extraHostEntries |= [{"ip":'$IP_ONLY',"interface":["K8S-CP-1"]}]' -i controlplane.yaml

# Check if a USB disk is detected and adjust disk configuration accordingly
CHECK_USB=$(talosctl get disks -e $IP_ONLY -n $IP_ONLY --insecure | awk '$8 == "usb" {print $4}')
if [ "$CHECK_USB" -eq 1 ]; then
  # If USB is detected, set installation disk to /dev/sdb
  echo "SETTING UP DISK TO /dev/sdb AS USB IS ENABLED"
  disk="/dev/sdb"
  yq e '.machine.install.disk="'$disk'"' -i controlplane.yaml
else
  echo "SKIPPING DISK CONFIG PART --- USB IS USED"
fi

# Configure Talos control plane endpoint and node for communication
echo "#SETTING UP Control Plane IP in TALOSCONFIG FOR COMMUNICATION"
talosctl config endpoint $IP_ONLY
talosctl config node $IP_ONLY

# Add Tailscale IP and control plane IP to certificate SANs for secure communication
yq e '.machine.certSANs |= ["'$IP_ONLY'","'$CONTROLPLANE_TS_IP'"]' -i controlplane.yaml
yq e '.cluster.apiServer.certSANs |= ["'$IP_ONLY'","'$CONTROLPLANE_TS_IP'"]' -i controlplane.yaml
popd > /dev/null

# Apply the Talos configuration to the control plane node with a reboot
echo "APPLYING TALOS CONFIG"
echo "talosctl apply-config --nodes $IP_ONLY --insecure --file ControlPlane/controlplane.yaml -p Common/tailscale.patch.yaml --mode reboot"
talosctl apply-config --nodes $IP_ONLY --insecure --file ControlPlane/controlplane.yaml -p Common/tailscale.patch.yaml --mode reboot