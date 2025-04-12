# 🚀 TalosOS Homelab Setup Guide

![TalosOS Logo](https://avatars.githubusercontent.com/u/13804887?s=200&v=4)

This comprehensive guide will walk you through setting up a production-grade Kubernetes cluster using TalosOS. The setup includes one control plane node and one worker node, connected securely through Tailscale.

## 📋 Prerequisites

Before you begin, ensure you have:

- Two physical machines (nodes) for control plane and worker
- USB drive (8GB minimum) for installation
- Access to router for static IP configuration
- Tailscale account
- Basic understanding of Kubernetes and networking concepts

## 🛠️ Hardware Requirements

| Component | Control Plane | Worker Node |
|-----------|--------------|-------------|
| CPU       | 2+ cores     | 2+ cores    |
| RAM       | 4GB+         | 4GB+        |
| Storage   | 20GB+        | 20GB+       |
| Network   | 1Gbps+       | 1Gbps+      |

## 🔄 Installation Steps

### 1️⃣ Initial Setup

#### Create Bootable USB
1. Download the TalosOS ISO from [official website](https://www.talos.dev/latest/introduction/quickstart/)
2. Create a bootable USB using the ISO
3. Place the USB in the ISO folder



#### Tailscale Configuration
1. Create a Tailscale account at [tailscale.com](https://tailscale.com)
2. Generate a new Tailscale Auth Key
3. Update the `TS_AUTH_KEY` variable in `.env` file

```bash
TS_AUTH_KEY="tskey-auth-XXX-XXXX-XXXXX-XXXXXXX-XXXXX"
```

#### Network Setup
1. Configure static IP on your router for both nodes
2. Document the following details for each node:
   - Static IP address
   - Gateway
   - Network interface name
   - Disk path

### 2️⃣ Control Plane Setup (Node-1)

#### Environment Configuration
Update the following variables in `.env`:

```bash
CP_IP="xxx.xxx.xxx.xxx/24"
CP_HOSTNAME="k8s-cp-1"
Gateway="xxx.xxx.xxx.xxx"
Interface="eth0"
disk="/disk/sda"
```

#### Installation Process
1. Plug the USB into Node-1
2. Run prerequisites:
   ```bash
   ./Pre-req-#0.sh
   ```
3. Initialize control plane:
   ```bash
   ./Intialize-ControlPlane-#2.sh
   ```
4. Wait for installation to complete
5. Verify kubelet status and connectivity


#### Kubernetes Bootstrap
1. Run bootstrap script:
   ```bash
   ./Bootstrap-K8s-#2.sh
   ```
2. Wait for the process to complete
3. Verify cluster status:
   ```bash
   kubectl get nodes
   ```

### 3️⃣ Worker Node Setup (Node-2)

#### Environment Configuration
Update the following variables in `.env`:

```bash
WORKER_NODE_IP="xxx.xxx.xxx.xxx/24"
WORKER_NODE_TS_IP="100.63.xxx.xxx"
```

#### Installation Process
1. Plug the USB into Node-2
2. Run worker node initialization:
   ```bash
   ./Intialize-WorkerNode-#3.sh
   ```
3. Wait for installation to complete


## ✅ Verification

After completing all steps, verify your setup:

1. Check cluster status:
   ```bash
   kubectl get nodes
   ```
2. Verify Tailscale connectivity:
   ```bash
   tailscale status
   ```
3. Test pod deployment:
   ```bash
   kubectl run nginx --image=nginx
   kubectl get pods
   ```

## 🔧 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Installation fails | Check USB drive and ISO integrity |
| Network connectivity issues | Verify static IP and gateway settings |
| Tailscale connection problems | Regenerate auth key and update .env |
| Kubernetes bootstrap failure | Check control plane status and logs |

### Log Collection
```bash
# Control plane logs
talosctl logs -n $CP_IP

# Worker node logs
talosctl logs -n $WORKER_NODE_IP
```

## 📚 Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `TALOSCTL_VERSION` | Version of talosctl | "1.9.2" |
| `KUBECTL_VERSION` | Version of kubectl | "1.30.1" |
| `CP_IP` | Control plane static IP | "192.168.1.100/24" |
| `CONTROLPLANE_TS_IP` | Control plane Tailscale IP | "100.63.xxx.xxx" |
| `CP_HOSTNAME` | Control plane hostname | "k8s-cp-1" |
| `Gateway` | Router gateway | "192.168.1.1" |
| `Interface` | Network interface name | "eth0" |
| `disk` | Disk path | "/disk/sda" |
| `TS_AUTH_KEY` | Tailscale auth key | "tskey-auth-XXX-XXXX-XXXXX-XXXXXXX-XXXXX" |
| `WORKER_NODE_IP` | Worker node static IP | "192.168.1.101/24" |
| `WORKER_NODE_TS_IP` | Worker node Tailscale IP | "100.63.xxx.xxx" |

