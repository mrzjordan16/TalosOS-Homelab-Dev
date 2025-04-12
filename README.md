# TalosOS Homelab Setup Guide

This guide will walk you through setting up a Kubernetes cluster using TalosOS with one control plane and one worker node.

## Prerequisites

- Three physical machines (nodes) for control plane and worker
- USB drive for installation
- Access to router for static IP configuration
- Tailscale account

## Step 1: Initial Setup

1. **Create Bootable USB**
   - Download the TalosOS ISO from the official website
   - Create a bootable USB using the ISO
   - Place the USB in the ISO folder
   - A LAPTOP/REMOTE COMPUTER

2. **Tailscale Setup**
   - Create a Tailscale account if you don't have one
   - Generate a new Tailscale Auth Key
   - Update the `TS_AUTH_KEY` variable in `.env` file with your generated key

3. **Network Configuration**
   - Configure static IP on your router for both nodes
   - Note down the following details for each node:
     - Static IP address
     - Gateway
     - Network interface name
     - Disk path

## Step 2: Control Plane Setup (Node-1)

1. **Environment Configuration**
   - Update the following variables in `.env`:
     - `CP_IP`: Static LAN IP for control plane
     - `CP_HOSTNAME`: Desired hostname for control plane
     - `Gateway`: Router gateway (ROUTER IP)
     - `Interface`: Network interface name (NETWORK INTERFACE)
     - `disk`: Disk path (e.g., "/disk/sda")
     - Run `Pre-req-#0.sh` to install prerequisites (talosctl,kubectl and yq)
      
2. **Installation Process**
   - Plug the USB into Node-1
   - Execute `Intialize-ControlPlane-#2.sh` to install TalosOS
   - Wait for installation to complete and kubelet to reach ready state
   - Verify connectivity status is OK

3. **Kubernetes Bootstrap**
   - Run `Bootstrap-K8s-#2.sh` to provision Kubernetes control plane
   - Wait for the process to complete

## Step 3: Worker Node Setup (Node-2)

1. **Environment Configuration**
   - Update the following variables in `.env`:
     - `WORKER_NODE_IP`: Static IP for worker node
     - `WORKER_NODE_TS_IP`: Tailscale IP for worker node

2. **Installation Process**
   - Plug the USB into Node-2
   - Execute `Intialize-WorkerNode-#3.sh`
   - Wait for the installation to complete

## Verification

After completing all steps, you should have:
- A running Kubernetes control plane on Node-1
- A worker node on Node-2
- Both nodes connected through Tailscale
- A fully functional Kubernetes cluster

## Troubleshooting

If you encounter any issues:
1. Verify all environment variables are correctly set
2. Check network connectivity between nodes
3. Ensure Tailscale is properly configured on both nodes
4. Verify disk paths and network interfaces are correct

## Environment Variables Reference

| Variable | Description |
|----------|-------------|
| `TALOSCTL_VERSION` | Version of talosctl |
| `KUBECTL_VERSION` | Version of kubectl |
| `CP_IP` | Control plane static IP |
| `CONTROLPLANE_TS_IP` | Control plane Tailscale IP |
| `CP_HOSTNAME` | Control plane hostname |
| `Gateway` | Router gateway |
| `Interface` | Network interface name |
| `disk` | Disk path for installation |
| `TS_AUTH_KEY` | Tailscale authentication key |
| `USB_INSTALLED` | USB installation flag |
| `MAIN_DIRECTORY` | Main project directory |
| `image` | TalosOS installer image |
| `WORKER_NODE_IP` | Worker node static IP |
| `WORKER_NODE_TS_IP` | Worker node Tailscale IP |
