#!/bin/bash

# Enable allexport to load environment variables from .env file
set -o allexport
source .env
set +o allexport

# Extract the control plane IP without the subnet mask
IP_ONLY="${CP_IP%/*}"

# Bootstrap the Talos cluster using the control plane IP as both node and endpoint
talosctl bootstrap -n $IP_ONLY -e $IP_ONLY

# Wait for 80 seconds to allow the bootstrap process to stabilize
sleep 80

# Retrieve the Kubernetes configuration file for the cluster
talosctl kubeconfig -n $IP_ONLY -e $IP_ONLY

# Check the status of Kubernetes nodes to verify the cluster setup
kubectl get nodes