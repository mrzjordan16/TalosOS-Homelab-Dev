#!/bin/bash

set -o allexport
source .env
set +o allexport
# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd ${SCRIPT_DIR}/
cd ${MAIN_DIRECTORY}/

# Initialize index
index=1
IFS=', ' read -r -a WORKER_NODE_TS <<< "$WORKER_NODE_IP_TS_IP"
# Use tr to replace commas with spaces and loop over the result
for value in $(echo "$WORKER_NODE_IP" | tr ',' ' '); do
    pushd Worker  > /dev/null
    IP_ONLY="${value%/*}"
    echo $IP_ONLY
    cp worker.yaml worker-$index.yaml
    echo "DISK WIPE PROPERTY TRUE"
    yq e '.machine.install.image= "'$image'"' -i worker.yaml
    yq e '.machine.install.image= "'$image'"' -i worker-$index.yaml
    yq e '.machine.install.wipe =true' -i worker-$index.yaml

    echo "DISK PROPERTY PATH"
    CHECK_USB=$(talosctl get disks -e $IP_ONLY -n $IP_ONLY --insecure | awk '$8 == "usb" {print $4}')
    if [ "$CHECK_USB" -eq 1 ]; then
    #ENABLE IT IF TALOS OS IS INSTALLED AND WITHOUT USING USB
    echo "SETTING UP DISK TO /dev/sdb/ AS USB IS ENABLED"
    disk="/dev/sdb"
    yq e '.machine.install.disk="'$disk'"' -i worker-$index.yaml
    else
        echo "SKIPPING DISK CONFIG PART --- USB IS USED"
    fi

    echo "SETTING UP HOSTNAME"
    Hostname="K8S-WK-$index" 
    yq e '.machine.network.hostname= "'$Hostname'"' -i worker-$index.yaml
    echo "SETTING UP NETWORK"
    yq e '.machine.network.nameservers |= ["8.8.8.8", "8.8.4.4", "'$Gateway'"]' -i worker-$index.yaml
    yq e '.machine.network.interfaces |= [{"interface":"'$Interface'","addresses":["'$IP_ONLY'/24"],"routes":[{"network":"0.0.0.0/0","gateway":"'$Gateway'"}],"dhcp":false}]' -i worker-$index.yaml
    yq e '.machine.time.servers |= ["time.google.com"]' -i worker-$index.yaml
    # #SETTING UP TAILSCALE CONFIGURATION IN CONTROLPLANE
    yq e '.machine.certSANs |= ["'$IP_ONLY'","'${WORKER_NODE_TS[$index-1]}'"]' -i worker-$index.yaml
    popd > /dev/null
    pushd Common  > /dev/null
    echo "SETTING UP WORKER NODE"
    talosctl apply-config --nodes $IP_ONLY --insecure --file $SCRIPT_DIR/$MAIN_DIRECTORY/Worker/worker-$index.yaml -p @tailscale.patch.yaml --mode reboot
    popd > /dev/null
    # Increment index
    ((index++))
done
