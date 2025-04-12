#!/bin/bash

set -e

# Detect OS and Architecture
OS=$(uname | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Normalize architecture names
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64 | arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

#DOWNLOAD YQ
if [ -x "/usr/local/bin/yq" ]; then
    echo "yq is installed in /usr/local/bin"
    echo "SKIPPING INSTALLATION PART"
else
    echo "yq is NOT installed in /usr/local/bin"
    YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep tag_name | cut -d '"' -f 4)
    YQ_BINARY="yq_${OS}_${ARCH}"
    DOWNLOAD_URL="https://github.com/mikefarah/yq/releases/latest/download/${YQ_BINARY}"
    echo "Installing yq version $YQ_VERSION for $OS/$ARCH..."
    # Download binary
    curl -L "$DOWNLOAD_URL" -o yq
    chmod +x yq

    # Move to /usr/local/bin (use sudo if necessary)
    if [ "$EUID" -ne 0 ]; then
        sudo mv yq /usr/local/bin/yq
    else
        mv yq /usr/local/bin/yq
    fi
    echo "✅ yq installed at /usr/local/bin/yq"
fi 



#DOWNLOAD TALOSCTL
if [ -x "/usr/local/bin/talosctl" ]; then
    echo "talosctl is installed in /usr/local/bin"
    echo "SKIPPING INSTALLATION PART"
else
    if [ -z "$TALOSCTL_VERSION" ] || [ "$TALOSCTL_VERSION" == "0" ]; then
        echo "No TALOSCTL_VERSION specified or TALOSCTL_VERSION is 0. Fetching the latest release..."

        # Fetch the latest TALOSCTL_VERSION of talosctl from GitHub API
        TALOSCTL_VERSION=$(curl -s https://api.github.com/repos/siderolabs/talos/releases/latest | jq -r .tag_name | sed 's/^v//')

        if [ -z "$TALOSCTL_VERSION" ]; then
            echo "Failed to fetch the latest TALOSCTL_VERSION."
            exit 1
        fi
    fi
    # Construct download URL for talosctl
    download_url="https://github.com/siderolabs/talos/releases/download/v$TALOSCTL_VERSION/talosctl-$TALOSCTL_VERSION-$os-$arch"

    echo "Downloading talosctl TALOSCTL_VERSION $TALOSCTL_VERSION for $os/$arch..."

    # Download the binary
    curl -L "$download_url" -o talosctl
    chmod +x talosctl

    # Move it to /usr/local/bin or current directory
    if [ "$EUID" -ne 0 ]; then
        echo "Moving talosctl to current directory"
        mv talosctl /usr/local/bin/talosctl
    else
        echo "Moving talosctl to /usr/local/bin"
        sudo mv talosctl /usr/local/bin/talosctl
    fi

    echo "talosctl version $TALOSCTL_VERSION installed successfully."
fi



#DOWNLOAD KUBECTL
if [ -x "/usr/local/bin/kubectl" ]; then
    echo "kubectl is installed in /usr/local/bin"
    echo "SKIPPING INSTALLATION PART"
else
    # Check if the version is empty, "", or 0
    if [ -z "$KUBECTL_VERSION" ] || [ "$KUBECTL_VERSION" == "0" ]; then
        echo "No version specified or version is 0. Fetching the latest release..."

        # Fetch the latest version of kubectl from GitHub API
        KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)

        if [ -z "$KUBECTL_VERSION" ]; then
            echo "Failed to fetch the latest version."
            exit 1
        fi
    fi

    # Construct download URL for kubectl
    download_url="https://dl.k8s.io/release/v$KUBECTL_VERSION/bin/$os/$arch/kubectl"

    echo "Downloading kubectl version $KUBECTL_VERSION for $os/$arch..."

    # Download the binary
    curl -LO "$download_url"
    chmod +x kubectl

    # Move it to /usr/local/bin or current directory
    if [ "$EUID" -ne 0 ]; then
        echo "Moving kubectl to current directory"
        mv kubectl /usr/local/bin/kubectl
    else
        echo "Moving kubectl to /usr/local/bin"
        sudo mv kubectl /usr/local/bin/kubectl
    fi

    echo "kubectl version $KUBECTL_VERSION installed successfully."
fi